defmodule ApiTest do
  use ExUnit.Case
  use Plug.Test

  import Mock

  alias Api
  alias Core

  ##############
  # Attributes #
  ##############

  @opts Api.init([])

  #################
  # Aux functions #
  #################

  defp assert_405_response(conn) do
    assert conn.state == :sent
    assert conn.status == 405
    assert conn.resp_body == ""
  end

  #########
  # Tests #
  #########

  describe "/status" do
    test "returns 200 OK" do
      # Arrange
      conn = conn(:get, "/status")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == ""
    end
  end

  describe "/cars" do
    test_with_mock "returns 200 OK when the list of cars is loaded correctly", Core,
      [
        validate_cars: fn cars -> {:ok, cars} end,
        load_cars: fn _cars -> {:ok, :list_saved_successfully} end
      ] do
      # Arrange
      body_params = "[
        {\"id\": 1, \"seats\": 4},
        {\"id\": 2, \"seats\": 6}
      ]"

      conn =
        :put
        |> conn("/cars", body_params)
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == ""

      validated_cars = [%{"id" => 1, "seats" => 4}, %{"id" => 2, "seats" => 6}]

      assert_called Core.validate_cars(validated_cars)
      assert_called Core.load_cars(validated_cars)
    end

    test_with_mock "returns 500 when it fails to load cars", Core,
      [
        validate_cars: fn cars -> {:ok, cars} end,
        load_cars: fn
          _cars -> {:error, {:unable_to_save_cars, [%{"id" => 1, "seats" => 4}]}}
        end
      ] do
      # Arrange
      body_params = "[
        {\"id\": 1, \"seats\": 4},
        {\"id\": 2, \"seats\": 6}
      ]"

      conn =
        :put
        |> conn("/cars", body_params)
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 500
      assert conn.resp_body == ""

      validated_cars = [%{"id" => 1, "seats" => 4}, %{"id" => 2, "seats" => 6}]

      assert_called Core.validate_cars(validated_cars)
      assert_called Core.load_cars(validated_cars)
    end

    @tag :wip
    test_with_mock "returns 206 when it fails to load some cars", Core,
      [
        validate_cars: fn cars -> {:ok, cars} end,
        load_cars: fn
          _cars -> {:partial_ok, {:unable_to_save_cars, [%{"id" => 1, "seats" => 4}]}}
        end
      ] do
      # Arrange
      body_params = "[
        {\"id\": 1, \"seats\": 4},
        {\"id\": 2, \"seats\": 6}
      ]"

      conn =
        :put
        |> conn("/cars", body_params)
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 206
      assert conn.resp_body == ""

      validated_cars = [%{"id" => 1, "seats" => 4}, %{"id" => 2, "seats" => 6}]

      assert_called Core.validate_cars(validated_cars)
      assert_called Core.load_cars(validated_cars)
    end

    test_with_mock "returns 400 when the request format is incorrect", Core,
      [
        validate_cars: fn query -> {:error, {:invalid_format, query}} end,
      ] do
      # Arrange
      body_params = "[{\"id\": 1}]"

      conn =
        :put
        |> conn("/cars", body_params)
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""

      assert_called Core.validate_cars([%{"id" => 1}])
    end

    test "returns 400 when the request has incorrect headers" do
      # Arrange
      conn = conn(:put, "/cars")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""
    end

    test "returns 400 when the request has no JSON body" do
      # Arrange
      body_params = ""

      conn =
        :put
        |> conn("/cars", body_params)
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""
    end

    test "returns 400 when the request has invalid JSON body" do
      # Arrange
      body_params = "[{\"id\": 1}"

      conn =
        :put
        |> conn("/cars", body_params)
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      # Act & Assert
      parser_error =
        "malformed request, a Jason.DecodeError exception was raised with message \"unexpected end of input at position 10\""

      assert_raise Plug.Parsers.ParseError, parser_error, fn ->
        Api.call(conn, @opts)
      end

      assert_received {:plug_conn, :sent}
      assert {400, _headers, "Your JSON is malformed: [{\"id\": 1}"} = sent_resp(conn)
    end

    test "returns 405 when called with GET" do
      # Arrange
      conn = conn(:get, "/cars")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end

    test "returns 405 when called with POST" do
      # Arrange
      conn = conn(:post, "/cars")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end

    test "returns 405 when called with DELETE" do
      # Arrange
      conn = conn(:delete, "/cars")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end
  end

  describe "/journey" do
    test_with_mock "returns 200 OK when the group is registered correctly", Core,
      [
        validate_group: fn group -> {:ok, group} end,
        perform_journey: fn _group -> {:ok, nil} end
      ] do
      # Arrange
      body_params = "{\"id\": 1, \"people\": 4}"

      conn =
        :post
        |> conn("/journey", body_params)
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == ""

      validated_groups = %{"id" => 1, "people" => 4}

      assert_called Core.validate_group(validated_groups)
      assert_called Core.perform_journey(validated_groups)
    end

    test_with_mock "returns 400 when the request format is incorrect", Core,
      [
        validate_group: fn query -> {:error, {:invalid_format, query}} end,
      ] do
      # Arrange
      body_params = "{\"id\": 1}"

      conn =
        :post
        |> conn("/journey", body_params)
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""

      assert_called Core.validate_group(%{"id" => 1})
    end

    test "returns 400 when the request has incorrect headers" do
      # Arrange
      conn = conn(:post, "/journey")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""
    end

    test "returns 400 when the request has no JSON body" do
      # Arrange
      body_params = ""

      conn =
        :post
        |> conn("/journey", body_params)
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""
    end

    test "returns 400 when the request has invalid JSON body" do
      # Arrange
      body_params = "[{\"id\": 1}"

      conn =
        :post
        |> conn("/journey", body_params)
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      # Act & Assert
      parser_error =
        "malformed request, a Jason.DecodeError exception was raised with message \"unexpected end of input at position 10\""

      assert_raise Plug.Parsers.ParseError, parser_error, fn ->
        Api.call(conn, @opts)
      end

      assert_received {:plug_conn, :sent}
      assert {400, _headers, "Your JSON is malformed: [{\"id\": 1}"} = sent_resp(conn)
    end

    test "returns 405 when called with GET" do
      # Arrange
      conn = conn(:get, "/journey")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end

    test "returns 405 when called with PUT" do
      # Arrange
      conn = conn(:put, "/journey")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end

    test "returns 405 when called with DELETE" do
      # Arrange
      conn = conn(:delete, "/journey")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end
  end

  describe "/dropoff" do
    test_with_mock "returns 200 OK when the group is dropped off", Core,
      [
        validate_group_id: fn _query -> {:ok, %{"id" => 1}} end,
        end_journey: fn _group_id -> {:ok, 1} end
      ] do
      # Arrange
      body_params = "ID=1"
      unchecked_group_id = %{"ID" => "1"}
      checked_group_id = %{"id" => 1}

      conn =
        :post
        |> conn("/dropoff", body_params)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == ""

      assert_called Core.validate_group_id(unchecked_group_id)
      assert_called Core.end_journey(checked_group_id)
    end

    test_with_mock "returns 404 OK when the group is not found", Core,
      [
        validate_group_id: fn _group -> {:ok, %{"id" => 1}}  end,
        end_journey: fn _group -> {:error, {:group_not_found, 1}} end
      ] do
      # Arrange
      body_params = "ID=1"
      unchecked_group_id = %{"ID" => "1"}
      checked_group_id = %{"id" => 1}

      conn =
        :post
        |> conn("/dropoff", body_params)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 404
      assert conn.resp_body == ""

      assert_called Core.validate_group_id(unchecked_group_id)
      assert_called Core.end_journey(checked_group_id)
    end

    test_with_mock "returns 400 when the request format is incorrect", Core,
      [
        validate_group_id: fn query -> {:error, {:unable_to_convert_to_integer, query}} end,
      ] do
      # Arrange
      body_params = "ID=a"

      conn =
        :post
        |> conn("/dropoff", body_params)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""

      assert_called Core.validate_group_id(%{"ID" => "a"})
    end

    test "returns 400 when the request has incorrect headers" do
      # Arrange
      conn = conn(:post, "/dropoff")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""
    end

    test "returns 400 when the request has no body" do
      # Arrange
      body_params = ""

      conn =
        :post
        |> conn("/dropoff", body_params)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""
    end

    test "returns 405 when called with GET" do
      # Arrange
      conn = conn(:get, "/dropoff")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end

    test "returns 405 when called with PUT" do
      # Arrange
      conn = conn(:put, "/dropoff")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end

    test "returns 405 when called with DELETE" do
      # Arrange
      conn = conn(:delete, "/dropoff")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end
  end

  describe "/locate" do
    setup do
      %{
        body_params: "ID=1",
        unparsed_group_id: %{"ID" => "1"},
        parsed_group_id: %{"id" => 1},
        car: %{"id" => 1, "seats" => 4}
      }
    end

    test_with_mock "returns 200 OK and the car as a JSON payload", %{
      body_params: body_params,
      unparsed_group_id: unparsed_group_id,
      parsed_group_id: parsed_group_id,
      car: car
    }, Core, [],
      [
        validate_group_id: fn _group -> {:ok, parsed_group_id} end,
        where_is_group: fn _group_id -> {:ok, car} end
      ] do

      # Arrange
      json_car = Jason.encode!(car)

      conn =
        :post
        |> conn("/locate", body_params)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == json_car

      assert_called Core.validate_group_id(unparsed_group_id)
      assert_called Core.where_is_group(parsed_group_id)
    end

    test_with_mock "returns 204 OK when the group is waiting", %{
      body_params: body_params,
      unparsed_group_id: unparsed_group_id,
      parsed_group_id: parsed_group_id,
    }, Core, [],
      [
        validate_group_id: fn _group -> {:ok, parsed_group_id} end,
        where_is_group: fn _group_id -> {:ok, :waiting} end
      ] do
      conn =
        :post
        |> conn("/locate", body_params)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 204
      assert conn.resp_body == ""

      assert_called Core.validate_group_id(unparsed_group_id)
      assert_called Core.where_is_group(parsed_group_id)
    end

    test_with_mock "returns 404 OK when the group is not found", %{
      body_params: body_params,
      unparsed_group_id: unparsed_group_id,
      parsed_group_id: parsed_group_id,
    }, Core, [],
      [
        validate_group_id: fn _group -> {:ok, parsed_group_id} end,
        where_is_group: fn group_id -> {:error, {:group_not_found, group_id}} end
      ] do
      conn =
        :post
        |> conn("/locate", body_params)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 404
      assert conn.resp_body == ""

      assert_called Core.validate_group_id(unparsed_group_id)
      assert_called Core.where_is_group(parsed_group_id)
    end

    test_with_mock "returns 400 when the request format is incorrect", _ctx,
      Core, [],
      [
        validate_group_id: fn query -> {:error, {:unable_to_convert_to_integer, query}} end,
      ] do
      # Arrange
      body_params = "ID=a"

      conn =
        :post
        |> conn("/locate", body_params)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""

      assert_called Core.validate_group_id(%{"ID" => "a"})
    end

    test "returns 400 when the request has incorrect headers" do
      # Arrange
      conn = conn(:post, "/locate")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""
    end

    test "returns 400 when the request has no body" do
      # Arrange
      body_params = ""

      conn =
        :post
        |> conn("/locate", body_params)
        |> put_req_header("content-type", "application/x-www-form-urlencoded")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""
    end

    test "returns 405 when called with GET" do
      # Arrange
      conn = conn(:get, "/locate")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end

    test "returns 405 when called with PUT" do
      # Arrange
      conn = conn(:put, "/locate")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end

    test "returns 405 when called with DELETE" do
      # Arrange
      conn = conn(:delete, "/locate")

      # Act
      conn = Api.call(conn, @opts)

      # Assert
      assert_405_response(conn)
    end
  end

  describe "error handling" do
    test_with_mock "returns 500 if there is a crash", Core,
      [
        validate_cars: fn _cars -> raise RuntimeError end
      ] do
      # Arrange
      body_params = "[
        {\"id\": 1, \"seats\": 4},
        {\"id\": 2, \"seats\": 6}
      ]"

      conn =
        :put
        |> conn("/cars", body_params)
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      # Act & Assert
      assert_raise Plug.Conn.WrapperError, fn ->
        Api.call(conn, @opts)
      end

      assert_received {:plug_conn, :sent}
      assert {500, _headers, "Something unexpected went wrong. Please try again later."} = sent_resp(conn)
    end
  end
end
