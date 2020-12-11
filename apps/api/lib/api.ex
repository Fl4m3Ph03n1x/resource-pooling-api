defmodule Api do
  @moduledoc """
  Plug Router for all incoming requests.
  Dispatches the requests to the correct controllers.
  """

  use Plug.{Router, ErrorHandler}

  alias Api.Controllers.{Cars, Groups, Journeys, NotAllowed, Status}

  plug Plug.Logger
  plug :match
  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass:  ["text/*"],
    json_decoder: Jason
  plug :dispatch

  get     "/status",  do: Status.process(conn)
  put     "/cars",    do: Cars.process(conn)
  post    "/journey", do: Journeys.start(conn)
  post    "/dropoff", do: Journeys.finish(conn)
  post    "/locate",  do: Groups.find(conn)

  match _, do: NotAllowed.process(conn)

  @spec handle_errors(Plug.Conn.t, map) :: Plug.Conn.t
  def handle_errors(conn, %{kind: :error, reason: %Plug.Parsers.ParseError{}, stack: _stack} = err), do:
    send_resp(conn, conn.status, "Your JSON is malformed: #{err.reason.exception.data}")

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}), do:
    send_resp(conn, conn.status, "Something unexpected went wrong. Please try again later.")
end
