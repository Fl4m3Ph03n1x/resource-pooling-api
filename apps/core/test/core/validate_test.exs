defmodule Core.ValidateTest do
  use ExUnit.Case

  alias Core.Validate

  describe "format" do
    test "returns OK if data has correct format" do
      # Arrange
      data = [%{"id" => 1, "seats" => 6}, %{"id" => 2, "seats" => 4}]

      # Act and Assert
      actual = Validate.format(data)
      expected = {:ok, data}

      assert actual == expected
    end

    test "returns partial_ok with if only some data is invalid" do
      # Arrange
      data = [%{"id" => 1}, %{"id" => 2, "seats" => 4}]

      # Act and Assert
      actual = Validate.format(data)
      expected = {:partial_ok, {:invalid_cars, [{:missing_seats, %{"id" => 1}}]}}

      assert actual == expected
    end

    test "returns error if it has no seats" do
      # Arrange
      bad_car = %{"id" => 1}
      data = [bad_car]

      # Act and Assert
      actual = Validate.format(data)
      expected = {:error, {:malformed_data, [{:missing_seats, bad_car}]}}

      assert actual == expected
    end

    test "returns error if seats is not a number" do
      # Arrange
      bad_car = %{"id" => 1, "seats" => "NaN"}
      data = [bad_car]

      # Act and Assert
      actual = Validate.format(data)
      expected = {:error, {:malformed_data, [{:seats_must_be_integer, bad_car}]}}

      assert actual == expected
    end

    test "returns error if seats is too low" do
      # Arrange
      bad_car = %{"id" => 1, "seats" => 2}
      data = [bad_car]

      # Act and Assert
      actual = Validate.format(data)
      expected = {:error, {:malformed_data, [{:not_enough_seats, bad_car}]}}

      assert actual == expected
    end

    test "returns error if seats is too high" do
      # Arrange
      bad_car = %{"id" => 1, "seats" => 9}
      data = [bad_car]

      # Act and Assert
      actual = Validate.format(data)
      expected = {:error, {:malformed_data, [{:too_many_seats, bad_car}]}}

      assert actual == expected
    end

    test "returns error if it has no id" do
      # Arrange
      bad_car = %{"seats" => 5}
      data = [bad_car]

      # Act and Assert
      actual = Validate.format(data)
      expected = {:error, {:malformed_data, [{:missing_id, bad_car}]}}

      assert actual == expected
    end

    test "returns error if id is not a number" do
      # Arrange
      bad_car = %{"id" => "NaN", "seats" => 4}
      data = [bad_car]

      # Act and Assert
      actual = Validate.format(data)
      expected = {:error, {:malformed_data, [{:id_must_be_integer, bad_car}]}}

      assert actual == expected
    end

    test "returns error if id is too low" do
      # Arrange
      bad_car = %{"id" => -1, "seats" => 5}
      data = [bad_car]

      # Act and Assert
      actual = Validate.format(data)
      expected = {:error, {:malformed_data, [{:id_must_be_positive, bad_car}]}}

      assert actual == expected
    end

    test "returns error if it receives an invalid list" do
      # Arrange
      data = %{}

      # Act and Assert
      actual = Validate.format(data)
      expected = {:error, {:invalid_cars_list, data}}

      assert actual == expected
    end
  end

end
