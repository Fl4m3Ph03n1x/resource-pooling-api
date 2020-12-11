
defmodule Api.Controllers.Groups do
  @moduledoc """
  Controller for endpoints related to Groups.
  Does basic validation and resorts to the correspondant Flow for the logic.
  Translates the response from logic into HTTP responses.
  """

  use Rop

  alias Api.Validate
  alias Api.Workflow.Groups, as: Flow
  alias Jason
  alias Plug.Conn
  alias Plug.Conn.Status

  ##########
  # Public #
  ##########

  @spec find(Conn.t) :: Conn.t
  def find(conn), do:
    conn
    |> Validate.headers([{"content-type", "application/x-www-form-urlencoded"}])
    >>> Validate.url_encoded_body()
    >>> Flow.find()
    |> handle_flow_response(conn)

  ###########
  # Private #
  ###########

  @spec handle_flow_response({atom, any}, Conn.t) :: Conn.t
  defp handle_flow_response({:ok, :waiting}, conn), do:
    Conn.send_resp(conn, Status.code(:no_content), "")

  defp handle_flow_response({:ok, car}, conn), do:
    Conn.send_resp(conn, Status.code(:ok), "#{Jason.encode!(car)}")

  defp handle_flow_response({:error, {:group_not_found, _group_id}}, conn), do:
    Conn.send_resp(conn, Status.code(:not_found), "")

  defp handle_flow_response({:error, {_reason, _data}}, conn), do:
    Conn.send_resp(conn, Status.code(:bad_request), "")

end
