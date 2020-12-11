defmodule Storage.Entity.Groups do
  @moduledoc """
  Manages data about groups.
  Persists data in an ETS table where the key is the group_id and the value the
  amount of people in said group.

  Mainly used when ending journeys, so as to know how many seats will be freed
  in the car the group was travelling on. Can also be used for quick group
  lookups to check if groups exist or not.
  """

  alias ETS.Set, as: ESet
  alias Storage.{EtsHelpers, Settings}

  ##########
  # Public #
  ##########

  def save(%{"id" => id, "people" => people} = group), do:
    Settings.groups_table_name()
    |> ESet.wrap_existing!()
    |> ESet.put_new({id, people})
    |> EtsHelpers.handle_modify_entry_response(group)

  def delete(group_id), do:
    Settings.groups_table_name()
    |> ESet.wrap_existing!()
    |> ESet.delete(group_id)
    |> EtsHelpers.handle_modify_entry_response(group_id)

  def get(id), do:
    Settings.groups_table_name()
    |> ESet.wrap_existing!()
    |> ESet.get(id)
    |> handle_get_response(id)

  def reset, do:
    Settings.groups_table_name()
    |> ESet.wrap_existing!()
    |> ESet.delete_all()
    |> EtsHelpers.handle_reset_response()

  ###########
  # Private #
  ###########

  defp handle_get_response({:ok, nil}, _id), do:
    {:ok, nil}

  defp handle_get_response({:ok, {id, people}}, _id), do:
    {:ok, %{"id" => id, "people" => people}}

  defp handle_get_response({:error, reason}, id), do: {:error, {reason, id}}

end
