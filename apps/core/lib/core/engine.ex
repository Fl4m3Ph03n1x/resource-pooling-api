defmodule Core.Engine do
  @moduledoc """
  Contains logic to load cars.
  """

  use Rop

  alias Storage

  ##########
  # Public #
  ##########

  def load_cars(cars) do
    with {:ok, :table_reseted} <- Storage.reset_groups(),
      {:ok, :table_reseted} <- Storage.reset_seats(),
      {:ok, :table_reseted} <- Storage.reset_journeys(),
      {:ok, :table_reseted} <- Storage.reset_cars() do
        to_response_format(register_cars(cars), cars)
    end
  end

  ###########
  # Private #
  ###########

  defp register_cars(cars), do:
    cars
    |> Enum.map(&register_car/1)
    |> Enum.filter(&failed_save?/1)
    |> Enum.map(&extract_failed_reasons/1)

  defp register_car(car), do:
    car
    |> Storage.save_car()
    >>> Storage.add_seats()

  defp failed_save?({:ok, _car}), do: false
  defp failed_save?({:error, _reason}), do: true

  defp extract_failed_reasons({:error, reason}), do: reason

  defp to_response_format([], _total), do:
    {:ok, :list_saved_successfully}

  defp to_response_format(failed_saves, total) when length(failed_saves) == length(total), do:
    {:error, {:unable_to_save_cars, failed_saves}}

  defp to_response_format(failed_saves, _total), do:
    {:partial_ok, {:unable_to_save_cars, failed_saves}}

end
