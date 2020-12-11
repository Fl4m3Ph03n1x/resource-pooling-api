defmodule Api.Controllers.NotAllowed do
  @moduledoc """
  Runs when an endpoint is called with the wrong HTTP method.
  Used as the default operator for all non matching requests.
  """

  alias Plug.Conn
  alias Plug.Conn.Status

  ##########
  # Public #
  ##########

  @spec process(Conn.t) :: Conn.t
  def process(%Conn{} = conn), do:
    Conn.send_resp(conn, Status.code(:method_not_allowed), "")

end
