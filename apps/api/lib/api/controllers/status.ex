
defmodule Api.Controllers.Status do
  @moduledoc """
  Basic ping controller which will always return 200.
  Used periodically to check if the server is alive.
  """

  alias Plug.Conn
  alias Plug.Conn.Status

  ##########
  # Public #
  ##########

  @spec process(Conn.t) :: Conn.t
  def process(%Conn{} = conn), do: Conn.send_resp(conn, Status.code(:ok), "")

end
