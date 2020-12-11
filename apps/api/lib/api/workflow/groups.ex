defmodule Api.Workflow.Groups do
  @moduledoc """
  Flow for the Groups controller.
  Has the logic to:
   - find in which car a group is
  """

  alias Api.Workflow
  alias Core

  use Rop

  ##########
  # Public #
  ##########

  @spec find(Workflow.query) :: Workflow.result
  def find(query), do:
    query
    |> Core.validate_group_id()
    >>> Core.where_is_group()

end
