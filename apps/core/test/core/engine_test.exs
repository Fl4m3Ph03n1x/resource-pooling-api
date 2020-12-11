defmodule Core.EngineTest do
  use ExUnit.Case

  import Mock

  alias Core.Engine
  alias Storage

  describe "load_cars" do
    test_with_mock "returns OK when list is saved successfully", Storage, [],
    [
      reset_groups: fn -> {:ok, :table_reseted} end,
      reset_seats: fn -> {:ok, :table_reseted} end,
      reset_journeys: fn -> {:ok, :table_reseted} end,
      reset_cars: fn -> {:ok, :table_reseted} end,
      save_car: fn data -> {:ok, data} end,
      add_seats: fn data -> {:ok, data} end
    ] do
      # Arrange
      car1 =  %{"id" => 1, "seats" => 4}
      car2 = %{"id" => 2, "seats" => 5}
      car3 = %{"id" => 3, "seats" => 4}
      cars = [car1, car2, car3]

      # Act
      actual = Engine.load_cars(cars)
      expected = {:ok, :list_saved_successfully}

      # Assert
      assert actual == expected
      assert_reset()
      assert_called Storage.save_car(car1)
      assert_called Storage.save_car(car2)
      assert_called Storage.save_car(car3)
      assert_called Storage.add_seats(car1)
      assert_called Storage.add_seats(car2)
      assert_called Storage.add_seats(car3)
    end

    test_with_mock "returns error when it cannot save car to storage", Storage, [],
    [
      reset_groups: fn -> {:ok, :table_reseted} end,
      reset_seats: fn -> {:ok, :table_reseted} end,
      reset_journeys: fn -> {:ok, :table_reseted} end,
      reset_cars: fn -> {:ok, :table_reseted} end,
      save_car: fn data -> {:error, {:reason, data}} end,
    ] do
      # Arrange
      car1 = %{"id" => 1, "seats" => 4}
      cars = [car1]

      # Act
      actual = Engine.load_cars(cars)
      expected = {:error, {:unable_to_save_cars, [{:reason, car1}]}}

      # Assert
      assert actual == expected
      assert_reset()
      assert_called Storage.save_car(car1)
      assert_not_called Storage.add_seats(car1)
    end

    test_with_mock "returns error when it cannot reset storage", Storage, [],
    [
      reset_groups: fn -> {:ok, :table_reseted} end,
      reset_seats: fn -> {:error, :reason} end
    ] do
      # Arrange
      cars = [
        %{"id" => 1, "seats" => 4}
      ]

      # Act
      actual = Engine.load_cars(cars)
      expected = {:error, :reason}

      # Assert
      assert actual == expected
      assert_called Storage.reset_groups()
      assert_called Storage.reset_seats()
      assert_not_called Storage.reset_cars()
      assert_not_called Storage.reset_journeys()
      assert_not_called Storage.save_car(:_, :_)
      assert_not_called Storage.add_seats(:_, :_)
    end

    test_with_mock "returns partial_ok when cars are saved and some fail", Storage, [],
    [
      reset_groups: fn -> {:ok, :table_reseted} end,
      reset_seats: fn -> {:ok, :table_reseted} end,
      reset_journeys: fn -> {:ok, :table_reseted} end,
      reset_cars: fn -> {:ok, :table_reseted} end,
      save_car: fn _car ->
          receive do
            {:mock_return, value} ->
              value
          after
            0 ->
              raise "called too many times"
          end
      end,
      add_seats: fn _car ->
        receive do
          {:mock_return, value} ->
            value
        after
          0 ->
            raise "called too many times"
        end
    end
    ] do
      # Arrange
      car1 = %{"id" => 1, "seats" => 4}
      car2 = %{"id" => 2, "seats" => 5}
      car3 = %{"id" => 3, "seats" => 4}
      cars = [car1, car2, car3]

      send self(), {:mock_return, {:ok, car1}}
      send self(), {:mock_return, {:ok, car1}}
      send self(), {:mock_return, {:error, {:reason, car2}}}
      send self(), {:mock_return, {:ok, car3}}
      send self(), {:mock_return, {:ok, car3}}

      # Act
      actual = Engine.load_cars(cars)
      expected = {:partial_ok, {:unable_to_save_cars, [{:reason, car2}]}}

      # Assert
      assert actual == expected
      assert_reset()
      assert_called Storage.save_car(car1)
      assert_called Storage.save_car(car2)
      assert_called Storage.save_car(car3)
    end
  end

  defp assert_reset do
    assert_called Storage.reset_groups()
    assert_called Storage.reset_seats()
    assert_called Storage.reset_journeys()
    assert_called Storage.reset_cars()
  end
end
