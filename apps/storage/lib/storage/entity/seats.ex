defmodule Storage.Entity.Seats do
  @moduledoc """
  Manages the amount of free seats available in cars.
  Persists data in ETS, where the key is a seat number and the value is a list
  of car_ids that possess the amount of free seats represented by the key.

  Every time a car is registered, it updates the ETS table.
  It is also used when journeys start and end and updated accordingly.
  """

  use Rop

  alias ETS.Set, as: ESet
  alias Storage.{EtsHelpers, Settings}

  ##############
  # Attributes #
  ##############

  @maximum_car_seats 6

  ##########
  # Public #
  ##########

  def register_new_car(%{"id" => _id, "seats" => seats} = car) do
    table = ESet.wrap_existing!(Settings.seats_table_name())

    table
    |> ESet.get(seats)
    >>> store(table, car)
    |> EtsHelpers.handle_modify_entry_response(car)
  end

  def get_cars_with_seat(key), do:
    Settings.seats_table_name()
    |> ESet.wrap_existing!()
    |> ESet.get(key)
    |> handle_response(key)

  def reset, do:
    Settings.seats_table_name()
    |> ESet.wrap_existing!()
    |> ESet.delete_all()
    |> EtsHelpers.handle_reset_response()

  def pop_available_car(seats) when seats <= @maximum_car_seats do
    case get_cars_with_seat(seats) do
      {:ok, nil} -> pop_available_car(seats + 1)
      {:ok, cars} -> update_seats(seats, cars)
      error -> error
    end
  end

  def pop_available_car(_seats), do: {:ok, nil}

  def update_seats_list(seats, []), do:
    Settings.seats_table_name()
    |> ESet.wrap_existing!()
    |> ESet.delete(seats)
    |> EtsHelpers.handle_modify_entry_response([])

  def update_seats_list(seats, new_car_ids), do:
    Settings.seats_table_name()
    |> ESet.wrap_existing!()
    |> ESet.put({seats, new_car_ids})
    |> EtsHelpers.handle_modify_entry_response(new_car_ids)

  ###########
  # Private #
  ###########

  defp store(nil, table, %{"id" => id, "seats" => seats}), do:
    ESet.put(table, {seats, [id]})

  defp store({seats, car_ids}, table, %{"id" => id, "seats" => seats}), do:
    ESet.put(table, {seats, [id | car_ids]})

  defp update_seats(seats, [car_to_pop | []]), do:
    Settings.seats_table_name()
    |> ESet.wrap_existing!()
    |> ESet.delete(seats)
    |> handle_update_response(car_to_pop, seats)

  defp update_seats(seats, [car_to_pop | cars]), do:
    Settings.seats_table_name()
    |> ESet.wrap_existing!()
    |> ESet.put({seats, cars})
    |> handle_update_response(car_to_pop, seats)

  defp handle_update_response({:ok, _table}, car_id, seats), do: {:ok, %{"id" => car_id, "seats" => seats}}
  defp handle_update_response({:error, reason}, _car_id, seats), do: {:error, {reason, seats}}

  defp handle_response({:error, reason}, params), do: {:error, {reason, params}}
  defp handle_response({:ok, {_seats, car_ids}}, _params), do: {:ok, car_ids}
  defp handle_response({:ok, result}, _params), do: {:ok, result}
end
