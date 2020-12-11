defmodule Storage.Application do
  @moduledoc false

  use Application

  alias Eternal
  alias Storage.Settings

  ##########
  # Public #
  ##########

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, args) do
    children = children(args)

    opts = [strategy: :one_for_one, name: Storage.Supervisor]
    Supervisor.start_link(children, opts)
  end

  ###########
  # Private #
  ###########

  @spec children([atom]) :: [Supervisor.child_spec]
  defp children([:test]), do: []

  defp children(_args), do: [
    %{
      id: CarsEternal,
      start: {Eternal, :start_link, [Settings.cars_table_name(), [:set, {:read_concurrency, true}]]}
    },
    %{
      id: JourneysEternal,
      start: {Eternal, :start_link, [Settings.journeys_table_name(), [:set, {:read_concurrency, true}]]}
    },
    %{
      id: SeatsEternal,
      start: {Eternal, :start_link, [Settings.seats_table_name(), [:set, {:read_concurrency, true}]]}
    },
    %{
      id: GroupsEternal,
      start: {Eternal, :start_link, [Settings.groups_table_name(), [:set, {:read_concurrency, true}]]}
    }
  ]

end
