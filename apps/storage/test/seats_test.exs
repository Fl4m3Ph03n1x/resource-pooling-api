defmodule Storage.SeatsTest do
  use ExUnit.Case

  import Mock

  alias ETS.Set
  alias Storage
  alias Storage.Settings

  setup_all do
    %{
      seats_table: Settings.seats_table_name()
    }
  end

  describe "register_new_car" do
    test_with_mock "returns OK when saving a car whose seats_number is the first in storage", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _seats -> {:ok, nil} end,
      put: fn _table, _data -> {:ok, %Set{}} end,
    ] do
      # Arrange
      seat = 4
      car = %{"id" => 1, "seats" => seat}
      expected_tuple = {4, [1]}

      # Act & Assert
      assert {:ok, car} = Storage.add_seats(car)
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.get(:_, seat)
      assert_called Set.put(:_, expected_tuple)
    end

    test_with_mock "returns OK when saving a car into storage when storage already has cars", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _seats -> {:ok, {4, [1]}} end,
      put: fn _table, _data -> {:ok, %Set{}} end,
    ] do
      # Arrange
      seat = 4
      car = %{"id" => 2, "seats" => seat}
      expected_tuple = {4, [2, 1]}

      # Act & Assert
      assert {:ok, _table} = Storage.add_seats(car)
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.get(:_, seat)
      assert_called Set.put(:_, expected_tuple)
    end

    test_with_mock "returns error if it fails to get data to store it", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _seats -> {:error, :reason} end
    ] do
      # Arrange
      seat = 4
      car = %{"id" => 1, "seats" => seat}

      # Act
      actual = Storage.add_seats(car)
      expected = {:error, {:reason, car}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.get(:_, seat)
      assert_not_called Set.put(:_, :_)
    end

    test_with_mock "returns error if it fails to store data", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _seats -> {:ok, nil} end,
      put: fn _table, _data -> {:error, :reason} end,
    ] do
      # Arrange
      seat = 4
      car = %{"id" => 1, "seats" => seat}
      expected_save_tuple = {4, [1]}

      # Act
      actual = Storage.add_seats(car)
      expected = {:error, {:reason, car}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.get(:_, seat)
      assert_called Set.put(:_, expected_save_tuple)
    end
  end

  describe "get_cars_with_seat" do
    test_with_mock "returns OK if it got data successfully", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _key -> {:ok, {4, [1]}} end,
    ] do
      # Arrange
      seats = 4

      # Act
      actual = Storage.get_car_ids_with_seat(seats)
      expected = {:ok, [1]}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.get(:_, seats)
    end

    test_with_mock "returns error if it fails to get data", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _key -> {:error, :reason} end,
    ] do
      # Arrange
      seats = 4

      # Act
      actual = Storage.get_car_ids_with_seat(seats)
      expected = {:error, {:reason, seats}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.get(:_, seats)
    end
  end

  describe "reset" do
    test_with_mock "returns OK if table is reseted successfully", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete_all: fn _table -> {:ok, nil} end,
    ] do

      assert {:ok, _table} = Storage.reset_seats()
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.delete_all(%Set{})
    end

    test_with_mock "returns error if it fails to reset table", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete_all: fn _table -> {:error, :reason} end,
    ] do

      assert {:error, :reason} = Storage.reset_seats()
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.delete_all(%Set{})
    end
  end

  describe "pop_available_car" do
    test_with_mock "returns nil if there is no car available", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _seats -> {:ok, nil} end
    ] do
      # Arrange
      people = 4

      # Act
      actual = Storage.pop_available_car_with_seats(people)
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.get(:_, people)
      assert_called Set.get(:_, people + 1)
      assert_called Set.get(:_, people + 2)
      assert_not_called Set.put(:_, :_)
    end

    test_with_mock "deletes entry if poped car is the last one in the list", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _seats -> {:ok, [1]} end,
      delete: fn _table, _key -> {:ok, %Set{}} end
    ] do
      # Arrange
      people = 4

      # Act
      actual = Storage.pop_available_car_with_seats(people)
      expected = {:ok, %{"id" => 1, "seats" => 4}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.get(:_, people)
      assert_called Set.delete(:_, people)
      assert_not_called Set.put(:_, :_)
    end

    test_with_mock "returns the first available car", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _seats -> {:ok, {4, [1, 2, 3]}} end,
      put: fn _table, _data -> {:ok, %Set{}} end
    ] do
      # Arrange
      people = 4

      # Act
      actual = Storage.pop_available_car_with_seats(people)
      expected = {:ok, %{"id" => 1, "seats" => 4}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.get(:_, people)
      assert_called Set.put(:_, {4, [2, 3]})
    end

    test_with_mock "returns error if it cannot get seats when popping cars", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _seats -> {:error, :reason} end
    ] do
      # Arrange
      people = 4

      # Act
      actual = Storage.pop_available_car_with_seats(people)
      expected = {:error, {:reason, people}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.get(:_, people)
      assert_not_called Set.put(:_, :_)
    end

    test_with_mock "returns error if it cannot save popped cars", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _seats -> {:ok, {4, [1, 2, 3]}} end,
      put: fn _table, _data -> {:error, :reason} end
    ] do
      # Arrange
      people = 4

      # Act
      actual = Storage.pop_available_car_with_seats(people)
      expected = {:error, {:reason, people}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.get(:_, people)
      assert_called Set.put(:_, {4, [2, 3]})
    end
  end

  describe "update_seats_list" do
    test_with_mock "returns OK when updating a list is successfull", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      put: fn _table, _data -> {:ok, %Set{}} end,
    ] do
      # Arrange
      seats = 4
      new_car_ids = [1, 2, 3]
      expected_tuple = {seats, new_car_ids}

      # Act & Assert
      assert {:ok, car} = Storage.update_car_ids_for_seat(seats, new_car_ids)
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.put(:_, expected_tuple)
    end

    test_with_mock "deletes entry if given list is empty", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete: fn _table, _data -> {:ok, %Set{}} end,
    ] do
      # Arrange
      seats = 4
      new_car_ids = []

      # Act & Assert
      assert {:ok, car} = Storage.update_car_ids_for_seat(seats, new_car_ids)
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.delete(:_, seats)
    end

    test_with_mock "returns error when list update fails", %{
      seats_table: seats_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      put: fn _table, _data -> {:error, :reason} end,
    ] do
      # Arrange
      seats = 4
      new_car_ids = [1, 2, 3]

      # Act
      actual = Storage.update_car_ids_for_seat(seats, new_car_ids)
      expected = {:error, {:reason, new_car_ids}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(seats_table)
      assert_called Set.put(:_, {seats, new_car_ids})
    end
  end
end
