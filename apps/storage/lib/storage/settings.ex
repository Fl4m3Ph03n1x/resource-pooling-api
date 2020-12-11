defmodule Storage.Settings do
  @moduledoc """
  Main access point for configuration variables.

  In this case, these variables do no depend on the value of MIX_ENV, so they
  are presented as static values here.
  """

  @spec cars_table_name :: :cars
  def cars_table_name, do: :cars

  @spec journeys_table_name :: :journeys
  def journeys_table_name, do: :journeys

  @spec groups_table_name :: :groups
  def groups_table_name, do: :groups

  @spec seats_table_name :: :seats
  def seats_table_name, do: :seats
end
