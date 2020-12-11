defmodule Api.Validate do
  @moduledoc """
  Contains validation functions for incoming requests.
  Validates:
   - headers
   - json
   - url_encoded_body
  """

  use Rop

  alias Jason
  alias Plug.Conn

  ##########
  # Public #
  ##########

  @spec headers(Conn.t, [{String.t, String.t}]) :: {:ok, Conn.t}
  | {:error, {:missing_mandatory_headers, String.t}}
  def headers(%Conn{} = conn, headers) do
    mandatory_headers_set = MapSet.new(headers)
    request_headers_set = MapSet.new(conn.req_headers)
    missing_headers = MapSet.difference(mandatory_headers_set, request_headers_set)

    if Enum.empty?(missing_headers) do
      {:ok, conn}
    else
      {:error, {:missing_mandatory_headers, mapset_to_string(missing_headers)}}
    end
  end

  @spec json(Conn.t) :: {:ok, map}
  | {:error, {:missing_request_body, :body_not_present}}
  def json(%Conn{} = conn), do:
    conn.body_params
    |> validate_body_exists()
    >>> extract_json()

  @spec url_encoded_body(Conn.t) :: {:ok, map}
  | {:error, {:missing_request_body, :body_not_present}}
  def url_encoded_body(%Conn{} = conn), do:
    validate_body_exists(conn.body_params)

  ###########
  # Private #
  ###########

  @spec validate_body_exists(map) :: {:ok, map}
  | {:error, {:missing_request_body, :body_not_present}}
  defp validate_body_exists(data) when data == %{}, do: {:error, {:missing_request_body, :body_not_present}}
  defp validate_body_exists(data), do: {:ok, data}

  @spec extract_json(map) :: {:ok, map}
  defp extract_json(%{"_json" => json}), do: {:ok, json}
  defp extract_json(json), do: {:ok, json}

  @spec mapset_to_string(MapSet.t) :: String.t
  defp mapset_to_string(headers), do:
    headers
    |> Enum.map(&tuple_to_string/1)
    |> Enum.join(", ")

  @spec tuple_to_string({String.t, String.t}) :: String.t
  defp tuple_to_string({key, val}), do: "{#{key}: #{val}}"
end
