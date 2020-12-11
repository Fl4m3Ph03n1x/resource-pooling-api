
defmodule Api.Controllers.Cars do
  @moduledoc """
  Controller for endpoints related to cars.
  Does basic validation and resorts to the correspondant Flow for the logic.
  Translates the response from logic into HTTP responses.
  """

  use Rop

  alias Api.Validate
  alias Api.Workflow.Cars, as: Flow
  alias Jason
  alias Plug.Conn
  alias Plug.Conn.Status

  ##########
  # Public #
  ##########

  @spec process(Conn.t) :: Conn.t
  def process(conn), do:
    conn
    |> Validate.headers([{"content-type", "application/json"}])
    >>> Validate.json()
    >>> Flow.load_cars()
    |> handle_flow_response(conn)

  ###########
  # Private #
  ###########

  @spec handle_flow_response({atom, any}, Conn.t) :: Conn.t
  defp handle_flow_response({:ok, :list_saved_successfully}, conn), do:
    Conn.send_resp(conn, Status.code(:ok), "")

  defp handle_flow_response({:partial_ok, {:unable_to_save_cars, _failed_saves}}, conn), do:
    Conn.send_resp(conn, Status.code(:partial_content), "")

  defp handle_flow_response({:error, {:unable_to_save_cars, _failed_saves}}, conn), do:
    Conn.send_resp(conn, Status.code(:internal_server_error), "")

  defp handle_flow_response({:error, {_reason, _data}}, conn), do:
    Conn.send_resp(conn, Status.code(:bad_request), "")

end
