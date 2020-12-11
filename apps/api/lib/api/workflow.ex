defmodule Api.Workflow do
  @moduledoc """
  Worflows represent the logic that controllers use. They implement the steps
  that requests need to take to be completed and return answer ready for the
  controllers to decode.
  This approach means all controllers will be very skim and easy to follow.
  Controllers are a detail, the logic should be independent from them. Workflows
  ensure that happens.
  """

  @type query :: map
  @type result :: {:ok, any} | {:error, any}
end
