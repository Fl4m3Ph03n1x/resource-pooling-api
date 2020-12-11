defmodule Api.Workflow.Cars do
  @moduledoc """
  Flow for the cars controller.
  Has the logic to:
   - load cars
  """

  alias Api.Workflow
  alias Core

  use Rop

  ##########
  # Public #
  ##########

  @spec load_cars(Workflow.query) :: Workflow.result | {:partial_ok, any}
  def load_cars(query), do:
    query
    |> Core.validate_cars()
    >>> Core.load_cars()

end
