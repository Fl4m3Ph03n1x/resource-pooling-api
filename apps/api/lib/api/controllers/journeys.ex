
defmodule Api.Controllers.Journeys do
  @moduledoc """
  Controller for endpoints related to Journeys.
  Does basic validation and resorts to the correspondant Flow for the logic.
  Translates the response from logic into HTTP responses.
  """

  use Rop

  alias Api.Validate
  alias Api.Workflow.Journeys, as: Flow
  alias Jason
  alias Plug.Conn
  alias Plug.Conn.Status

  ##########
  # Public #
  ##########

  @spec start(Conn.t) :: Conn.t
  def start(conn), do:
    conn
    |> Validate.headers([{"content-type", "application/json"}])
    >>> Validate.json()
    >>> Flow.start_journey()
    |> handle_flow_response(conn)

  @spec finish(Conn.t) :: Conn.t
  def finish(conn), do:
    conn
    |> Validate.headers([{"content-type", "application/x-www-form-urlencoded"}])
    >>> Validate.url_encoded_body()
    >>> Flow.end_journey()
    |> handle_flow_response(conn)

  ###########
  # Private #
  ###########

  @spec handle_flow_response({atom, any}, Conn.t) :: Conn.t
  defp handle_flow_response({:ok, _data}, conn), do:
    Conn.send_resp(conn, Status.code(:ok), "")

  defp handle_flow_response({:error, {:group_not_found, _group_id}}, conn), do:
    Conn.send_resp(conn, Status.code(:not_found), "")

  defp handle_flow_response({:error, {_reason, _data}}, conn), do:
    Conn.send_resp(conn, Status.code(:bad_request), "")

end
