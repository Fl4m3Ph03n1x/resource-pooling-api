defmodule Storage.Entity.Journeys do
  @moduledoc """
  Keeps track of which groups are in which cars.
  Persists data in an ETS table where the key is the group_id and the value is
  the car_id.

  If a group is waiting for a car, the key is group_id and the value is the atom
  :waiting.

  Additionaly, it also contains a special key, :waiting, which has as a value a
  list group_id's of all the groups currently waiting.

  Mainly used to find where groups are and to start and end journeys.
  """

  use Rop

  alias ETS.Set, as: ESet
  alias Storage.{EtsHelpers, Settings}

  ##########
  # Public #
  ##########

  def reset, do:
    Settings.journeys_table_name()
    |> ESet.wrap_existing!()
    |> ESet.delete_all()
    |> EtsHelpers.handle_reset_response()

  def register(nil, %{"id" => group_id}), do:
    Settings.journeys_table_name()
    |> ESet.wrap_existing!()
    |> ESet.put({group_id, :waiting})
    >>> add_to_waiting_list(group_id)
    |> EtsHelpers.handle_modify_entry_response(nil)

  def register(%{"id" => car_id}, %{"id" => group_id}), do:
    Settings.journeys_table_name()
    |> ESet.wrap_existing!()
    |> ESet.put({group_id, car_id})
    >>> remove_from_waiting_list(group_id)
    |> EtsHelpers.handle_modify_entry_response(car_id)

  def unregister(id), do:
    Settings.journeys_table_name()
    |> ESet.wrap_existing!()
    |> ESet.delete(id)
    >>> remove_from_waiting_list(id)
    |> EtsHelpers.handle_modify_entry_response(id)

  def get(id), do:
    Settings.journeys_table_name()
    |> ESet.wrap_existing!()
    |> ESet.get(id)
    |> handle_get_response(id)

  def get_waiting, do:
    Settings.journeys_table_name()
    |> ESet.wrap_existing!()
    |> ESet.get(:waiting)
    |> handle_waiting_response()

  ###########
  # Private #
  ###########

  defp add_to_waiting_list(table, group_id), do:
    table
    |> ESet.get(:waiting)
    >>> add_to_list_if_not_present(group_id, table)

  defp add_to_list_if_not_present(nil, id, table), do:
    ESet.put(table, {:waiting, [id]})

  defp add_to_list_if_not_present({:waiting, list}, id, table) do
    if Enum.member?(list, id) do
      {:ok, table}
    else
      ESet.put(table, {:waiting, [id | list]})
    end
  end

  defp remove_from_waiting_list(table, group_id), do:
    table
    |> ESet.get(:waiting)
    >>> is_waiting?(group_id)
    |> remove_from_list(group_id, table)

  defp is_waiting?(nil, _group_id), do: {false, nil}
  defp is_waiting?({:waiting, ids}, group_id), do:
    {Enum.member?(ids, group_id), ids}

  defp remove_from_list({false, _ids_list}, _id, table), do:
    {:ok, table}

  defp remove_from_list({true, ids_list}, id, table), do:
    ESet.put(table, {:waiting, List.delete(ids_list, id)})

  defp handle_get_response({:ok, {_group_id, :waiting}}, _id), do:
    {:ok, :waiting}

  defp handle_get_response({:ok, {_group_id, car_id}}, _id), do:
    {:ok, car_id}

  defp handle_get_response({:ok, nil}, id), do:
    {:error, {:group_not_found, id}}

  defp handle_get_response({:error, reason}, id), do: {:error, {reason, id}}

  defp handle_waiting_response({:ok, nil}), do: {:ok, []}
  defp handle_waiting_response({:ok, {:waiting, list}}), do: {:ok, list}
  defp handle_waiting_response(result), do: result

end
