defmodule Storage.CarsTest do
  use ExUnit.Case

  import Mock

  alias ETS.Set
  alias Storage
  alias Storage.Settings

  setup_all do
    %{
      cars_table: Settings.cars_table_name()
    }
  end

  describe "save" do
    test_with_mock "returns OK if car is saved", %{
      cars_table: cars_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      put: fn _table, _data -> {:ok, %Set{}} end,
    ] do
      # Arrange
      car = %{"id" => 1, "seats" => 4}

      # Act
      actual = Storage.save_car(car)
      expected = {:ok, car}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(cars_table)
      assert_called Set.put(:_, {1, 4})
    end

    test_with_mock "returns error if it fails to save car", %{
      cars_table: cars_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      put: fn _table, _data -> {:error, :reason} end,
    ] do
      # Arrange
      car = %{"id" => 1, "seats" => 4}

      # Act
      actual = Storage.save_car(car)
      expected = {:error, {:reason, car}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(cars_table)
      assert_called Set.put(:_, {1, 4})
    end
  end

  describe "delete" do
    test_with_mock "returns OK if car is deleted", %{
      cars_table: cars_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete: fn _table, _data -> {:ok, %Set{}} end,
    ] do
      # Arrange
      car_id = 1

      # Act
      actual = Storage.delete_car(car_id)
      expected = {:ok, car_id}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(cars_table)
      assert_called Set.delete(:_, car_id)
    end

    test_with_mock "returns error if it fails to delete car", %{
      cars_table: cars_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete: fn _table, _data -> {:error, :reason} end,
    ] do
      # Arrange
      car_id = 1

      # Act
      actual = Storage.delete_car(car_id)
      expected = {:error, {:reason, car_id}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(cars_table)
      assert_called Set.delete(:_, car_id)
    end
  end

  describe "get" do
    test_with_mock "returns car if it exists", %{
      cars_table: cars_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:ok, {1, 4}} end,
    ] do
      # Arrange
      car_id = 1

      # Act
      actual = Storage.find_car(car_id)
      expected = {:ok, %{"id" => 1, "seats" => 4}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(cars_table)
      assert_called Set.get(:_, car_id)
    end

    test_with_mock "returns nil if car does not exist", %{
      cars_table: cars_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:ok, nil} end,
    ] do
      # Arrange
      car_id = 1

      # Act
      actual = Storage.find_car(car_id)
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(cars_table)
      assert_called Set.get(:_, car_id)
    end

    test_with_mock "returns error if it fails to get car", %{
      cars_table: cars_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:error, :reason} end,
    ] do
      # Arrange
      car_id = 1

      # Act
      actual = Storage.find_car(car_id)
      expected = {:error, {:reason, car_id}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(cars_table)
      assert_called Set.get(:_, car_id)
    end
  end

  describe "reset" do
    test_with_mock "resets cars table", %{
      cars_table: cars_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete_all: fn _table -> {:ok, %Set{}} end,
    ] do

      # Act
      actual = Storage.reset_cars()
      expected = {:ok, :table_reseted}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(cars_table)
      assert_called Set.delete_all(:_)
    end

    test_with_mock "returns error if it fails to reset table", %{
      cars_table: cars_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete_all: fn _table -> {:error, :reason} end,
    ] do
      # Act
      actual = Storage.reset_cars()
      expected = {:error, :reason}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(cars_table)
      assert_called Set.delete_all(:_)
    end
  end
end
