
defmodule Core.JourneyTest do
  use ExUnit.Case, async: false

  import Mock

  alias Core.Journey
  alias Storage

  describe "validate_group" do
    test "returns OK when group is valid" do
      # Arrange
      group =  %{"id" => 1, "people" => 4}

      # Act
      actual = Journey.validate_group(group)
      expected = {:ok, group}

      # Assert
      assert actual == expected
    end

    test "returns error if group has no id" do
      # Arrange
      group =  %{"people" => 4}

      # Act
      actual = Journey.validate_group(group)
      expected = {:error, {:missing_id, group}}

      # Assert
      assert actual == expected
    end

    test "returns error if group id is not integer" do
      # Arrange
      group =  %{"id" => "1", "people" => 4}

      # Act
      actual = Journey.validate_group(group)
      expected = {:error, {:id_must_be_integer, group}}

      # Assert
      assert actual == expected
    end

    test "returns error if group id is negative" do
      # Arrange
      group =  %{"id" => -1, "people" => 4}

      # Act
      actual = Journey.validate_group(group)
      expected = {:error, {:id_must_be_positive, group}}

      # Assert
      assert actual == expected
    end

    test "returns error if group has no people" do
      # Arrange
      group =  %{"id" => 1}

      # Act
      actual = Journey.validate_group(group)
      expected = {:error, {:missing_people, group}}

      # Assert
      assert actual == expected
    end

    test "returns error if group people is not integer" do
      # Arrange
      group =  %{"id" => 1, "people" => "4"}

      # Act
      actual = Journey.validate_group(group)
      expected = {:error, {:people_must_be_integer, group}}

      # Assert
      assert actual == expected
    end

    test "returns error if group has too many people" do
      # Arrange
      group =  %{"id" => 1, "people" => 10}

      # Act
      actual = Journey.validate_group(group)
      expected = {:error, {:too_many_people, group}}

      # Assert
      assert actual == expected
    end

    test "returns error if group has not enough people" do
      # Arrange
      group =  %{"id" => 1, "people" => 0}

      # Act
      actual = Journey.validate_group(group)
      expected = {:error, {:not_enough_people, group}}

      # Assert
      assert actual == expected
    end
  end

  describe "validate_group_id" do
    test "returns converted ID" do
      # Arrange
      id =  %{"ID" => "1"}

      # Act
      actual = Journey.validate_group_id(id)
      expected = {:ok, %{"id" => 1}}

      # Assert
      assert actual == expected
    end

    test "returns error if input has incorrect format" do
      # Arrange
      id = %{"a" => nil}

      # Act
      actual = Journey.validate_group_id(id)
      expected = {:error, {:missing_id, %{"a" => nil}}}

      # Assert
      assert actual == expected
    end

    test "returns error if ID cannot be converted" do
      # Arrange
      id =  %{"ID" => "bad_id"}

      # Act
      actual = Journey.validate_group_id(id)
      expected = {:error, {:unable_to_convert_to_integer, id}}

      # Assert
      assert actual == expected
    end
  end

  describe "register" do
    setup do
      car_id = 1
      people = 4
      group_id = 1

      %{
        empty_car: %{"id" => car_id, "seats" => 4},
        full_car: %{"id" => car_id, "seats" => 0},
        car_id: car_id,
        people: people,
        group: %{"id" => group_id, "people" => people},
      }
    end

    test_with_mock "returns OK when it registers the journey correctly", %{
      empty_car: empty_car,
      full_car: full_car,
      car_id: car_id,
      group: group,
      people: people
    }, Storage, [],
    [
      save_group: fn group -> {:ok, group} end,
      pop_available_car_with_seats: fn _seats -> {:ok, empty_car} end,
      add_seats: fn _car -> {:ok, full_car} end,
      start_journey: fn _car, _group -> {:ok, car_id} end
    ] do
      # Act
      actual = Journey.register(group)
      expected = {:ok, car_id}

      # Assert
      assert actual == expected
      assert_called Storage.save_group(group)
      assert_called Storage.pop_available_car_with_seats(people)
      assert_called Storage.add_seats(full_car)
      assert_called Storage.start_journey(full_car, group)
    end

    test_with_mock "returns OK when it registers the journey as waiting to start", %{
      group: group
    }, Storage, [],
    [
      save_group: fn group -> {:ok, group} end,
      pop_available_car_with_seats: fn _seats -> {:ok, nil} end,
      start_journey: fn _car, _group -> {:ok, nil} end
    ] do
      # Arrange
      people = Map.get(group, "people")

       # Act
       actual = Journey.register(group)
       expected = {:ok, nil}

       # Assert
       assert actual == expected
       assert_called Storage.pop_available_car_with_seats(people)
       assert_called Storage.start_journey(nil, group)
    end

    test_with_mock "returns error if registering the journey fails", %{
      empty_car: empty_car,
      full_car: full_car,
      group: group
    }, Storage, [],
    [
      save_group: fn group -> {:ok, group} end,
      pop_available_car_with_seats: fn _seats -> {:ok, empty_car} end,
      add_seats: fn _car -> {:ok, full_car} end,
      start_journey: fn _car, _group -> {:error, :reason} end
    ] do
        # Arrange
        people = Map.get(group, "people")

        # Act
        actual = Journey.register(group)
        expected = {:error, {:reason, group}}

        # Assert
        assert actual == expected
        assert_called Storage.pop_available_car_with_seats(people)
        assert_called Storage.add_seats(full_car)
        assert_called Storage.start_journey(full_car, group)
    end
  end

  describe "unregister" do
    setup do
      car_id = 3
      seats = 6
      group_id = 1
      people = 4
      waiting_group_id = 2

      %{
        waiting_group: %{"id" => waiting_group_id, "people" => 4},
        waiting_group_ids: [waiting_group_id],
        car_id: car_id,
        seats: seats,
        car: %{"id" => car_id, "seats" => seats},
        group_id: group_id,
        people: people,
        group: %{"id" => group_id, "people" => people}
      }
    end

    test_with_mock "returns OK when it unregisters the journey and the group was in a car", %{
      car_id: car_id,
      seats: seats,
      group_id: group_id,
      people: people,
      car: car,
      group: group,
      waiting_group_ids: waiting_group_ids,
      waiting_group: waiting_group
    }, Storage, [],
    [
      find_group: fn _group_id -> {:ok, group} end,
      where_is_group: fn _group_id -> {:ok, car_id} end,
      find_car: fn _car_id -> {:ok, car} end,
      get_car_ids_with_seat: fn _seats -> {:ok, [1, 2, 3]} end,
      update_car_ids_for_seat: fn _seats, list -> {:ok, list} end,
      add_seats: fn car -> {:ok, car} end,
      end_journey: fn group_id -> {:ok, group_id} end,
      delete_group: fn group_id -> {:ok, group_id} end,
      get_waiting_groups: fn -> {:ok, waiting_group_ids} end,
      find_group: fn _id -> {:ok, waiting_group} end,
      save_group: fn group -> {:ok, group} end,
      pop_available_car_with_seats: fn _seats -> {:ok, car} end,
      start_journey: fn _car, _group -> {:ok, car_id} end
    ] do
      # Arrange
      new_car_ids_list = [1, 2]
      new_car =  %{"id" => car_id, "seats" => seats}
      group_data = %{"id" => group_id}
      waiting_group_id =  Map.get(waiting_group, "id")
      waiting_group_people =  Map.get(waiting_group, "people")
      maximum_free_seats_in_car = seats - people

      # Act
      actual = Journey.unregister(group_data)
      expected = {:ok, group_id}

      # Assert
      assert actual == expected
      assert_called Storage.find_group(group_id)
      assert_called Storage.where_is_group(group_id)
      assert_called Storage.find_car(car_id)
      assert_called Storage.get_car_ids_with_seat(maximum_free_seats_in_car)
      assert_called Storage.update_car_ids_for_seat(maximum_free_seats_in_car , new_car_ids_list)
      assert_called Storage.add_seats(new_car)
      assert_called Storage.end_journey(group_id)
      assert_called Storage.delete_group(group_id)

      assert_called Storage.get_waiting_groups()
      assert_called Storage.find_group(waiting_group_id)
      assert_called Storage.save_group(waiting_group)
      assert_called Storage.pop_available_car_with_seats(waiting_group_people)
      assert_called Storage.start_journey(%{"id" => 3, "seats" => 2}, waiting_group)
    end

    test_with_mock "returns OK when it unregisters the journey and the group was waiting", %{
      group_id: group_id,
      group: group
    }, Storage, [],
    [
      find_group: fn _group_id -> {:ok, group} end,
      where_is_group: fn _group_id -> {:ok, :waiting} end,
      end_journey: fn group_id -> {:ok, group_id} end,
      delete_group: fn group_id -> {:ok, group_id} end,
      get_waiting_groups: fn -> {:ok, []} end
    ] do
      # Arrange
      group_data = %{"id" => group_id}

      # Act
      actual = Journey.unregister(group_data)
      expected = {:ok, group_id}

      # Assert
      assert actual == expected
      assert_called Storage.find_group(group_id)
      assert_called Storage.where_is_group(group_id)
      assert_not_called Storage.find_car(:_)
      assert_not_called Storage.get_car_ids_with_seat(:_)
      assert_not_called Storage.update_car_ids_for_seat(:_ , :_)
      assert_not_called Storage.add_seats(:_)
      assert_called Storage.end_journey(group_id)
      assert_called Storage.delete_group(group_id)
      assert_called Storage.get_waiting_groups()
    end

    test_with_mock "returns error when group is not found", %{
      group_id: group_id,
    }, Storage, [],
    [
      find_group: fn _group_id -> {:ok, nil} end,
    ] do
      # Arrange
      group_data = %{"id" => group_id}

      # Act
      actual = Journey.unregister(group_data)
      expected = {:error, {:group_not_found, group_id}}

      # Assert
      assert actual == expected
      assert_called Storage.find_group(group_id)
      assert_not_called Storage.where_is_group(:_)
      assert_not_called Storage.find_car(:_)
      assert_not_called Storage.get_car_ids_with_seat(:_)
      assert_not_called Storage.update_car_ids_for_seat(:_ , :_)
      assert_not_called Storage.add_seats(:_)
      assert_not_called Storage.end_journey(:_)
      assert_not_called Storage.delete_group(:_)
    end

    test_with_mock "returns error if unregistering a journey fails", %{
      group_id: group_id,
      group: group
    }, Storage, [],
    [
      find_group: fn _group_id -> {:ok, group} end,
      where_is_group: fn _group_id -> {:error, :reason} end,
    ] do
      # Arrange
      group_data = %{"id" => group_id}

      # Act
      actual = Journey.unregister(group_data)
      expected = {:error, {:reason, group_id}}

      # Assert
      assert actual == expected
      assert_called Storage.find_group(group_id)
      assert_called Storage.where_is_group(group_id)
      assert_not_called Storage.find_car(:_)
      assert_not_called Storage.get_car_ids_with_seat(:_)
      assert_not_called Storage.update_car_ids_for_seat(:_ , :_)
      assert_not_called Storage.add_seats(:_)
      assert_not_called Storage.end_journey(:_)
      assert_not_called Storage.delete_group(:_)
    end
  end

  describe "where_is_group" do
    setup do
      car_id = 1
      group_id = 1

      %{
        group_id: group_id,
        parsed_group_id: %{"id" => group_id},
        car_id: car_id,
        car: %{"id" => car_id, "seats" => 4}
      }
    end

    test_with_mock "returns car if group is in a journey", %{
      parsed_group_id: parsed_group_id,
      car_id: car_id,
      car: car
    }, Storage, [], [
      where_is_group: fn _group_id -> {:ok, car_id} end,
      find_car: fn _car_id -> {:ok, car} end
    ] do
      # Arrange
      id = Map.get(parsed_group_id, "id")

      # Act
      actual = Core.where_is_group(parsed_group_id)
      expected = {:ok, car}

      # Assert
      assert actual == expected
      assert_called Storage.where_is_group(id)
      assert_called Storage.find_car(car_id)
    end

    test_with_mock "returns :waiting if group is waiting", %{
      parsed_group_id: parsed_group_id,
    }, Storage, [], [
      where_is_group: fn _group_id -> {:ok, :waiting} end
    ] do
      # Arrange
      id = Map.get(parsed_group_id, "id")

      # Act
      actual = Core.where_is_group(parsed_group_id)
      expected = {:ok, :waiting}

      # Assert
      assert actual == expected
      assert_called Storage.where_is_group(id)
      assert_not_called Storage.find_car(:_)
    end

    test_with_mock "returns error if group not found", %{
      group_id: group_id,
      parsed_group_id: parsed_group_id,
    }, Storage, [], [
      where_is_group: fn _group_id -> {:error, {:group_not_found, group_id}} end
    ] do

      # Act
      actual = Core.where_is_group(parsed_group_id)
      expected = {:error, {:group_not_found, parsed_group_id}}

      # Assert
      assert actual == expected
      assert_called Storage.where_is_group(group_id)
      assert_not_called Storage.find_car(:_)
    end
  end
end
