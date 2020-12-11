defmodule Api.Workflow.Journeys do
  @moduledoc """
  Flow for the Journeys controller.
  Has the logic to:
   - start a journey
   - end a journey
  """

  alias Api.Workflow
  alias Core

  use Rop

  ##########
  # Public #
  ##########

  @spec start_journey(Workflow.query) :: Workflow.result
  def start_journey(query), do:
    query
    |> Core.validate_group()
    >>> Core.perform_journey()

  @spec end_journey(Workflow.query) :: Workflow.result
  def end_journey(query), do:
    query
    |> Core.validate_group_id()
    >>> Core.end_journey()

end
