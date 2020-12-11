defmodule Core do
  @moduledoc """
  Entry point fo the Core layer.
  """

  alias Core.{Engine, Journey, Validate}

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
  @type group_id_query :: %{
    id :: String.t => String.t
  }
  @type parsed_group_id :: %{
    id :: String.t => non_neg_integer
  }
  @type error_reason :: {atom, any}

  #######
  # API #
  #######

  @spec load_cars(any) :: {:ok, :list_saved_successfully}
  | {:error, atom | {:unable_to_save_cars, [car]}}
  | {:partial_ok, {:unable_to_save_cars, [car]}}
  defdelegate load_cars(cars), to: Engine

  @spec validate_cars([car]) :: {:ok, [car]}
  | {:partial_ok, {atom, [error_reason]}}
  | {:error, {atom, [error_reason]}}
  defdelegate validate_cars(cars), to: Validate, as: :format

  @spec validate_group(group) :: {:ok, group} | {:error, error_reason}
  defdelegate validate_group(group), to: Journey

  @spec validate_group_id(group_id_query) :: {:ok, parsed_group_id} | {:error, error_reason}
  defdelegate validate_group_id(query), to: Journey
  defdelegate perform_journey(group), to: Journey, as: :register
  defdelegate end_journey(group), to: Journey, as: :unregister

  @spec where_is_group(parsed_group_id) :: {:ok, car | :waiting} | {:error, error_reason}
  defdelegate where_is_group(parsed_group_id), to: Journey
end
