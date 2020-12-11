defmodule Storage.Entity.Cars do
  @moduledoc """
  Represents cars as they were loaded.
  Persists data in an ETS table where the key is car_id and the value is seats.

  Mainly used to fetch the original car a group was travelling on.
  """

  alias ETS.Set, as: ESet
  alias Storage.{EtsHelpers, Settings}

  ##########
  # Public #
  ##########

  def save(%{"id" => id, "seats" => seats} = car), do:
    Settings.cars_table_name()
    |> ESet.wrap_existing!()
    |> ESet.put({id, seats})
    |> EtsHelpers.handle_modify_entry_response(car)

  def delete(id), do:
    Settings.cars_table_name()
    |> ESet.wrap_existing!()
    |> ESet.delete(id)
    |> EtsHelpers.handle_modify_entry_response(id)

  def get(id), do:
    Settings.cars_table_name()
    |> ESet.wrap_existing!()
    |> ESet.get(id)
    |> handle_get_response(id)

  def reset, do:
    Settings.cars_table_name()
    |> ESet.wrap_existing!()
    |> ESet.delete_all()
    |> EtsHelpers.handle_reset_response()

  ###########
  # Private #
  ###########

  defp handle_get_response({:ok, nil}, _id), do:
    {:ok, nil}

  defp handle_get_response({:ok, {id, seats}}, _id), do:
    {:ok, %{"id" => id, "seats" => seats}}

  defp handle_get_response({:error, reason}, id), do: {:error, {reason, id}}

end
