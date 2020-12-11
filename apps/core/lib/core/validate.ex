defmodule Core.Validate do
  @moduledoc """
  Contains validation logic for car lists and cars.
  """

  ##########
  # Public #
  ##########

  def format(cars) when is_list(cars) do
    bad_cars = Enum.reduce(cars, [], &get_bad_cars(&1, &2))

    cond do
      Enum.empty?(bad_cars) -> {:ok, cars}
      length(bad_cars) == length(cars) -> {:error, {:malformed_data, bad_cars}}
      true -> {:partial_ok, {:invalid_cars, bad_cars}}
    end
  end

  def format(bad_data), do: {:error, {:invalid_cars_list, bad_data}}

  ###########
  # Private #
  ###########

  defp get_bad_cars(car_data, acc) do
    with :ok <- validate_id(car_data),
      :ok <- validate_seats(car_data) do
        acc
      else
        {:error, reason} -> [reason | acc]
    end
  end

  defp validate_id(data) do
    id = Map.get(data, "id")
    cond do
      id == nil -> {:error, {:missing_id, data}}
      not is_integer(id) -> {:error, {:id_must_be_integer, data}}
      id < 0 -> {:error, {:id_must_be_positive, data}}
      true -> :ok
    end
  end

  defp validate_seats(data) do
    seats = Map.get(data, "seats")
    cond do
      seats == nil -> {:error, {:missing_seats, data}}
      not is_integer(seats) -> {:error, {:seats_must_be_integer, data}}
      seats > 6 -> {:error, {:too_many_seats, data}}
      seats < 4 -> {:error, {:not_enough_seats, data}}
      true -> :ok
    end
  end

end
