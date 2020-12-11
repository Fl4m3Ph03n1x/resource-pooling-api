defmodule Core.Journey do
  @moduledoc """
  Contains validation logic for Journeys and logic to register/unregister
  groups.

  It is also reponsible for finding groups that are making a journey or waiting
  for a car to start one.
  """

  use Rop

  alias Storage

  ##########
  # Public #
  ##########

  def validate_group_id(data), do:
    data
    |> validate_id()
    |> id_to_integer_maybe()

  def validate_group(group), do:
    group
    |> validate_id()
    >>>validate_people()

  def register(group), do:
    group
    |> Storage.save_group()
    >>> get_people()
    |> Storage.pop_available_car_with_seats()
    >>> update_seats(group)
    >>> Storage.start_journey(group)
    |> handle_response(group)

  def unregister(%{"id" => id}) do
    with {:ok, %{"id" => _group_id, "people" => people}} <- Storage.find_group(id),
      {:ok, car_id} <- Storage.where_is_group(id),
      {:ok, _car_id} <- free_seats(car_id, people),
      {:ok, _group_id} <- Storage.end_journey(id),
      {:ok, _group_id} <- Storage.delete_group(id),
      {:ok, waiting_group_ids} <- Storage.get_waiting_groups(),
      {:ok, waiting_groups} <- get_groups_data(waiting_group_ids),
      {:ok, _car_ids} <- re_register_groups(waiting_groups) do
        {:ok, id}
      else
        {:ok, nil} -> {:error, {:group_not_found, id}}
        {:error, reason} -> {:error, {reason, id}}
      end
  end

  def where_is_group(%{"id" => id} = parsed_group_id), do:
    id
    |> Storage.where_is_group()
    >>> find_car_maybe()
    |> handle_where_is_group_response(parsed_group_id)

  ###########
  # Private #
  ###########

  defp id_to_integer_maybe({:error, {:id_must_be_integer, %{"ID" => id} = data}}) do
    {:ok, %{"id" => String.to_integer(id)}}
  rescue
    _error -> {:error, {:unable_to_convert_to_integer, data}}
  end

  defp id_to_integer_maybe(error), do: error

  defp validate_id(data) do
    id = Map.get(data, "id") || Map.get(data, "ID")
    cond do
      id == nil -> {:error, {:missing_id, data}}
      not is_integer(id) -> {:error, {:id_must_be_integer, data}}
      id < 0 -> {:error, {:id_must_be_positive, data}}
      true -> {:ok, data}
    end
  end

  defp validate_people(data) do
    people = Map.get(data, "people")
    cond do
      people == nil -> {:error, {:missing_people, data}}
      not is_integer(people) -> {:error, {:people_must_be_integer, data}}
      people > 6 -> {:error, {:too_many_people, data}}
      people < 1 -> {:error, {:not_enough_people, data}}
      true -> {:ok, data}
    end
  end

  defp get_people(group), do: Map.get(group, "people")

  defp update_seats(nil, _group), do: {:ok, nil}

  defp update_seats(%{"id" => car_id, "seats" => seats}, %{"people" => people}), do:
    Storage.add_seats(%{"id" => car_id, "seats" => seats - people})

  defp free_seats(:waiting, _people), do: {:ok, nil}

  defp free_seats(car_id, people) do
    with {:ok, %{"id" => _car_id, "seats" => seats}} <- Storage.find_car(car_id) do
      unregister_car_seats(car_id, seats - people, people)
    end
  end

  defp unregister_car_seats(car_id, seats_to_search, people) when seats_to_search >= 0 do
    with {:ok, ids} <- Storage.get_car_ids_with_seat(seats_to_search) do
      cond do
        not is_list(ids) ->
          unregister_car_seats(car_id, seats_to_search - 1, people)

        Enum.member?(ids, car_id) ->
          new_ids = List.delete(ids, car_id)
          Storage.update_car_ids_for_seat(seats_to_search, new_ids)
          new_car = %{"id" => car_id, "seats" => seats_to_search + people}
          Storage.add_seats(new_car)
          {:ok, car_id}

        true ->
          unregister_car_seats(car_id, seats_to_search - 1, people)
      end
    end
  end

  defp unregister_car_seats(car_id, _seats_to_search, _people), do:
    {:error, {:car_has_no_seats_registered, car_id}}

  defp get_groups_data(group_ids), do:
    group_ids
    |> Enum.map(&Storage.find_group/1)
    |> all_ok?()
    |> extract_ok_data({:unable_to_get_group_data, group_ids})

  defp re_register_groups(groups), do:
    groups
    |> Enum.map(&register/1)
    |> all_ok?()
    |> extract_ok_data({:unable_register_groups, groups})

  defp handle_response({:ok, id}, _group), do: {:ok, id}
  defp handle_response({:error, reason}, group), do: {:error, {reason, group}}

  defp all_ok?(result_tuples), do:
    {not Enum.any?(result_tuples, &is_error_tuple?/1), result_tuples}

  defp is_error_tuple?({result, _data}), do: result == :error

  defp extract_ok_data({true, result_tuples}, _reason), do:
    {:ok, Enum.map(result_tuples, fn {:ok, data} -> data end)}

  defp extract_ok_data({false, _result_tuples}, reason), do:
    {:error, reason}

  defp find_car_maybe(:waiting), do: {:ok, :waiting}
  defp find_car_maybe(car_id), do: Storage.find_car(car_id)

  defp handle_where_is_group_response({:ok, data}, _parsed_group_id), do:
    {:ok, data}

  defp handle_where_is_group_response({:error, {reason, _data}}, parsed_group_id), do:
    {:error, {reason, parsed_group_id}}
end
