defmodule Storage.GroupsTest do
  use ExUnit.Case

  import Mock

  alias ETS.Set
  alias Storage
  alias Storage.Settings

  setup_all do
    %{
      groups_table: Settings.groups_table_name()
    }
  end

  describe "save" do
    test_with_mock "returns OK if group is saved", %{
      groups_table: groups_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      put_new: fn _table, _data -> {:ok, %Set{}} end,
    ] do
      # Arrange
      group = %{"id" => 1, "people" => 4}

      # Act
      actual = Storage.save_group(group)
      expected = {:ok, group}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(groups_table)
      assert_called Set.put_new(:_, {1, 4})
    end

    test_with_mock "returns error if it fails to save group", %{
      groups_table: groups_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      put_new: fn _table, _data -> {:error, :reason} end,
    ] do
      # Arrange
      group = %{"id" => 1, "people" => 4}

      # Act
      actual = Storage.save_group(group)
      expected = {:error, {:reason, group}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(groups_table)
      assert_called Set.put_new(:_, {1, 4})
    end
  end

  describe "delete" do
    test_with_mock "returns OK if group is deleted", %{
      groups_table: groups_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete: fn _table, _data -> {:ok, %Set{}} end,
    ] do
      # Arrange
      car_id = 1

      # Act
      actual = Storage.delete_group(car_id)
      expected = {:ok, car_id}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(groups_table)
      assert_called Set.delete(:_, car_id)
    end

    test_with_mock "returns error if it fails to delete group", %{
      groups_table: groups_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete: fn _table, _data -> {:error, :reason} end,
    ] do
      # Arrange
      car_id = 1

      # Act
      actual = Storage.delete_group(car_id)
      expected = {:error, {:reason, car_id}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(groups_table)
      assert_called Set.delete(:_, car_id)
    end
  end

  describe "get" do
    test_with_mock "returns group if it exists", %{
      groups_table: groups_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:ok, {1, 4}} end,
    ] do
      # Arrange
      id = 1

      # Act
      actual = Storage.find_group(id)
      expected = {:ok, %{"id" => 1, "people" => 4}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(groups_table)
      assert_called Set.get(:_, id)
    end

    test_with_mock "returns nil if group does not exist", %{
      groups_table: groups_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:ok, nil} end,
    ] do
      # Arrange
      id = 1

      # Act
      actual = Storage.find_group(id)
      expected = {:ok, nil}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(groups_table)
      assert_called Set.get(:_, id)
    end

    test_with_mock "returns error if it fails to get group", %{
      groups_table: groups_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      get: fn _table, _data -> {:error, :reason} end,
    ] do
      # Arrange
      id = 1

      # Act
      actual = Storage.find_group(id)
      expected = {:error, {:reason, id}}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(groups_table)
      assert_called Set.get(:_, id)
    end
  end

  describe "reset" do
    test_with_mock "resets groups table", %{
      groups_table: groups_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete_all: fn _table -> {:ok, %Set{}} end,
    ] do

      # Act
      actual = Storage.reset_groups()
      expected = {:ok, :table_reseted}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(groups_table)
      assert_called Set.delete_all(:_)
    end

    test_with_mock "returns error if it fails to reset table", %{
      groups_table: groups_table
    }, Set, [], [
      wrap_existing!: fn _table_name -> %Set{} end,
      delete_all: fn _table -> {:error, :reason} end,
    ] do
      # Act
      actual = Storage.reset_groups()
      expected = {:error, :reason}

      # Assert
      assert actual == expected
      assert_called Set.wrap_existing!(groups_table)
      assert_called Set.delete_all(:_)
    end
  end
end
