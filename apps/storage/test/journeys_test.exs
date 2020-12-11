defmodule Storage.JourneysTest do
  use ExUnit.Case

  import Mock

  alias ETS.Set
  alias Storage
  alias Storage.Settings

  setup_all do
    %{
      journeys_table: Settings.journeys_table_name()
    }
  end

  describe "register" do
    test_with_mock "returns OK if group is registered", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      put: fn _table, _data -> {:ok, %Set{}} end,
      get: fn _table, _group_id -> {:ok, nil} end
    ] do
      # Arrange
      group_id = 1
      car_id = 3
      car = %{"id" => car_id, "seats" => 6}
      group = %{"id" => group_id, "people" => 4}

      # Act
      actual = Storage.start_journey(car, group)
      expected = {:ok, car_id}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.put(:_, {group_id, car_id})
      assert_called Set.get(:_, :waiting)
    end

    test_with_mock "returns OK if group is re-registered", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      put: fn _table, _data -> {:ok, %Set{}} end,
      get: fn _table, _group_id -> {:ok, {:waiting, [1, 2, 3]}} end
    ] do
      # Arrange
      group_id = 1
      car_id = 3
      car = %{"id" => car_id, "seats" => 6}
      group = %{"id" => group_id, "people" => 4}

      # Act
      actual = Storage.start_journey(car, group)
      expected = {:ok, car_id}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.put(:_, {group_id, car_id})
      assert_called Set.get(:_, :waiting)
      assert_called Set.put(:_, {:waiting, [2, 3]})
    end

    test_with_mock "returns OK if group is registered as :waiting when there is no waiting list", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      put: fn _table, _data -> {:ok, %Set{}} end,
      get: fn _table, _key -> {:ok, nil} end
    ] do
      # Arrange
      group_id = 1
      car = nil
      group = %{"id" => group_id, "people" => 4}

      # Act
      actual = Storage.start_journey(nil, group)
      expected = {:ok, car}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.put(:_, {group_id, :waiting})
      assert_called Set.get(:_, :waiting)
      assert_called Set.put(:_, {:waiting, [group_id]})
    end

    test_with_mock "returns OK if group is registered as :waiting when there is a waiting list", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      put: fn _table, _data -> {:ok, %Set{}} end,
      put: fn _table, _data -> {:ok, %Set{}} end,
      get: fn _table, _key -> {:ok, {:waiting, [2, 3, 4]}} end
    ] do
      # Arrange
      group_id = 1
      car = nil
      group = %{"id" => group_id, "people" => 4}

      # Act
      actual = Storage.start_journey(nil, group)
      expected = {:ok, car}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.put(:_, {group_id, :waiting})
      assert_called Set.get(:_, :waiting)
      assert_called Set.put(:_, {:waiting, [4, 3, 2, group_id]})
    end

    test_with_mock "returns error if it fails to register a journey", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      put: fn _table, _key -> {:error, :reason} end
    ] do
      # Arrange
      car = nil
      group_id = 3
      group = %{"id" => group_id, "people" => 4}

      # Act
      actual = Storage.start_journey(car, group)
      expected = {:error, {:reason, car}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.put(:_, {group_id, :waiting})
    end
  end

  describe "unregister" do
    test_with_mock "returns OK if group is unregistered and there is no waiting list", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete: fn _table, _data -> {:ok, %Set{}} end,
      get: fn _table, _group_id -> {:ok, nil} end,
    ] do
      # Arrange
      group_id = 1

      # Act
      actual = Storage.end_journey(group_id)
      expected = {:ok, group_id}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.delete(:_, group_id)
      assert_called Set.get(:_, :waiting)
    end

    test_with_mock "returns OK if group is unregistered and there is a waiting list", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete: fn _table, _data -> {:ok, %Set{}} end,
      get: fn _table, _group_id -> {:ok, {:waiting, [2, 3, 4]}} end,
    ] do
      # Arrange
      group_id = 1

      # Act
      actual = Storage.end_journey(group_id)
      expected = {:ok, group_id}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.delete(:_, group_id)
      assert_called Set.get(:_, :waiting)
    end

    test_with_mock "returns OK if group is unregistered and is in the waiting list", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete: fn _table, _data -> {:ok, %Set{}} end,
      get: fn _table, _group_id -> {:ok, {:waiting, [1, 2, 3, 4]}} end,
      put: fn _table, _data -> {:ok, %Set{}} end
    ] do
      # Arrange
      group_id = 1

      # Act
      actual = Storage.end_journey(group_id)
      expected = {:ok, group_id}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.delete(:_, group_id)
      assert_called Set.get(:_, :waiting)
      assert_called Set.put(:_, {:waiting, [2, 3, 4]})
    end

    test_with_mock "returns error if it fails to unregister a group", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete: fn _table, _key -> {:error, :reason} end
    ] do
      # Arrange
      group_id = 3

      # Act
      actual = Storage.end_journey(group_id)
      expected = {:error, {:reason, group_id}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.delete(:_, group_id)
    end
  end

  describe "reset" do
    test_with_mock "returns OK if table is reseted successfully", %{
      journeys_table: journeys_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete_all: fn _table -> {:ok, nil} end,
    ] do

      assert {:ok, _table} = Storage.reset_journeys()
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.delete_all(%Set{})
    end

    test_with_mock "returns error if it fails to reset table", %{
      journeys_table: journeys_table
    }, Set, [],
    [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete_all: fn _table -> {:error, :reason} end,
    ] do

      assert {:error, :reason} = Storage.reset_journeys()
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.delete_all(%Set{})
    end
  end

  describe "get" do
    test_with_mock "returns car id of journey", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:ok, {1, 4}} end,
    ] do
      # Arrange
      group_id = 1

      # Act
      actual = Storage.where_is_group(group_id)
      expected = {:ok, 4}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.get(:_, group_id)
    end

    test_with_mock "returns :waiting if journey has not started", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:ok, {1, :waiting}} end,
    ] do
      # Arrange
      group_id = 1

      # Act
      actual = Storage.where_is_group(group_id)
      expected = {:ok, :waiting}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.get(:_, group_id)
    end

    test_with_mock "returns error if group is not found", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:ok, nil} end,
    ] do
      # Arrange
      group_id = 1

      # Act
      actual = Storage.where_is_group(group_id)
      expected = {:error, {:group_not_found, group_id}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.get(:_, group_id)
    end

    test_with_mock "returns error if it fails to get journey", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:error, :reason} end,
    ] do
      # Arrange
      group_id = 1

      # Act
      actual = Storage.where_is_group(group_id)
      expected = {:error, {:reason, group_id}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.get(:_, group_id)
    end
  end

  describe "get_waiting" do
    setup do
      %{
        waiting_list: [1, 2, 3]
      }
    end

    test_with_mock "returns waiting group ids if there is a waiting list", %{
      journeys_table: journeys_table,
      waiting_list: waiting_group_ids
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:ok, {:waiting, waiting_group_ids}} end,
    ] do
      # Act
      actual = Storage.get_waiting_groups()
      expected = {:ok, waiting_group_ids}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.get(:_, :waiting)
    end

    test_with_mock "returns an empty list if there are no groups waiting", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:ok, nil} end,
    ] do
      # Act
      actual = Storage.get_waiting_groups()
      expected = {:ok, []}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.get(:_, :waiting)
    end

    test_with_mock "returns error if it fails to get waiting groups", %{
      journeys_table: journeys_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:error, :reason} end,
    ] do
      # Act
      actual = Storage.get_waiting_groups()
      expected = {:error, :reason}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(journeys_table)
      assert_called Set.get(:_, :waiting)
    end
  end
end
