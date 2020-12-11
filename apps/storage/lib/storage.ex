defmodule Storage do
  @moduledoc """
  Entry point for the Storage layer.
  """

  alias ETS
  alias Storage.Entity.{Cars, Groups, Journeys, Seats}

  #########
  # Types #
  #########

  @type car :: %{
    id :: String.t => non_neg_integer,
    seats :: String.t => non_neg_integer
  }
  @type group :: %{
    id :: String.t => non_neg_integer,
    people :: String.t => non_neg_integer
  }
  @type error_reason :: atom
  @type seats :: non_neg_integer
  @type car_id :: non_neg_integer
  @type group_id :: non_neg_integer

  #########
  # Seats #
  #########

  @spec add_seats(car) :: {:ok, car} | {:error, {error_reason, car}}
  defdelegate add_seats(car), to: Seats, as: :register_new_car

  @spec update_car_ids_for_seat(seats, [car_id]) :: {:ok, [car_id]} | {:error, {error_reason, [car_id]}}
  defdelegate update_car_ids_for_seat(seats, new_car_ids), to: Seats, as: :update_seats_list

  @spec get_car_ids_with_seat(seats) :: {:ok, [car_id]} | {:error, {error_reason, seats}}
  defdelegate get_car_ids_with_seat(seats), to: Seats, as: :get_cars_with_seat

  @spec reset_seats :: {:ok, :table_reseted} | {:error, error_reason}
  defdelegate reset_seats, to: Seats, as: :reset

  @spec pop_available_car_with_seats(seats) :: {:ok, nil | car} | {:error, {error_reason, seats}}
  defdelegate pop_available_car_with_seats(seats), to: Seats, as: :pop_available_car

  ########
  # Cars #
  ########

  @spec save_car(car) :: {:ok, car} | {:error, {error_reason, car}}
  defdelegate save_car(car), to: Cars, as: :save

  @spec delete_car(car_id) :: {:ok, car_id} | {:error, {error_reason, car_id}}
  defdelegate delete_car(car_id), to: Cars, as: :delete

  @spec find_car(car_id) :: {:ok, car | nil} | {:error, {error_reason, car_id}}
  defdelegate find_car(id), to: Cars, as: :get

  @spec reset_cars :: {:ok, :table_reseted} | {:error, error_reason}
  defdelegate reset_cars, to: Cars, as: :reset

  ############
  # Journeys #
  ############

  @spec start_journey(car, group) :: {:ok, car_id | nil} | {:error, {error_reason, car_id | nil}}
  defdelegate start_journey(car, group), to: Journeys, as: :register

  @spec reset_journeys :: {:ok, :table_reseted} | {:error, error_reason}
  defdelegate reset_journeys, to: Journeys, as: :reset

  @spec where_is_group(group_id) :: {:ok, car_id | :waiting} | {:error, {error_reason, group_id}}
  defdelegate where_is_group(group_id), to: Journeys, as: :get

  @spec end_journey(group_id) :: {:ok, group_id} | {:error, {error_reason, group_id}}
  defdelegate end_journey(group_id), to: Journeys, as: :unregister

  @spec get_waiting_groups :: {:ok, [group_id]} | {:error, error_reason}
  defdelegate get_waiting_groups, to: Journeys, as: :get_waiting

  ##########
  # Groups #
  ##########

  @spec save_group(group) :: {:ok, group} | {:error, {error_reason, group}}
  defdelegate save_group(group), to: Groups, as: :save

  @spec find_group(group_id) :: {:ok, group | nil} | {:error, {error_reason, group_id}}
  defdelegate find_group(id), to: Groups, as: :get

  @spec delete_group(group_id) :: {:ok, group_id} | {:error, {error_reason, group_id}}
  defdelegate delete_group(group_id), to: Groups, as: :delete

  @spec reset_groups :: {:ok, :table_reseted} | {:error, error_reason}
  defdelegate reset_groups, to: Groups, as: :reset
end
