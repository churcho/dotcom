defmodule Schedules.HoursOfOperationTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Quixir
  import Schedules.HoursOfOperation
  alias Schedules.{HoursOfOperation, Departures}
  alias Pollution.VG

  describe "hours_of_operation/1" do
    test "returns basic hours for a route" do
      # does not validate the actual hours, that's in other tests
      actual = hours_of_operation("47")
      assert %HoursOfOperation{} = actual
      assert {week_0, week_1} = actual.week
      assert {saturday_0, saturday_1} = actual.saturday
      assert {sunday_0, sunday_1} = actual.sunday
      assert %Departures{} = week_0
      assert %Departures{} = week_1
      assert %Departures{} = saturday_0
      assert %Departures{} = saturday_1
      assert %Departures{} = sunday_0
      assert %Departures{} = sunday_1
    end

    test "can take a list of route IDs" do
      empty = %HoursOfOperation{}
      single_route = hours_of_operation(["50"])
      assert %HoursOfOperation{} = multiple_routes = hours_of_operation(["47", "50"])
      refute multiple_routes == empty
      refute multiple_routes == single_route
    end
  end

  describe "api_params/2" do
    test "for a given date, returns a query for each relevant day of the week and direction_id" do
      date = ~D[2017-12-01]
      route_id = "route_id"
      [week_date, saturday_date, sunday_date] = week_dates(date)
      actual = api_params([route_id], date)
      assert [week_query, saturday_query, sunday_query,
              week_query_1, saturday_query_1, sunday_query_1] = actual
      assert [
        {:route, ^route_id},
        {:date, ^week_date},
        {:direction_id, 0},
        {:stop_sequence, "first,last"} | _] = week_query
      assert week_query_1[:route] == route_id
      assert week_query_1[:direction_id] == 1
      assert week_query_1[:date] == week_date
      assert saturday_query[:route] == route_id
      assert saturday_query[:date] == saturday_date
      assert saturday_query_1[:route] == route_id
      assert saturday_query_1[:date] == saturday_date
      assert sunday_query[:route] == route_id
      assert sunday_query[:date] == sunday_date
      assert sunday_query_1[:route] == route_id
      assert sunday_query_1[:date] == sunday_date
    end
  end

  describe "parse_responses/1" do
    test "returns a timeout error if not all of the tasks complete within the timeout" do
      assert {:error, :timeout} = parse_responses([{:exit, :timeout}, {:ok, %JsonApi{}}, {:ok, %JsonApi{}},
                                                   {:ok, %JsonApi{}}, {:ok, %JsonApi{}}, {:ok, %JsonApi{}}])
    end

    test "returns a timeout error if the API returns an error" do
      # {:ok, _} is from Task.async_stream
      # {:error, [%JsonApi.Error{}]} is from JsonApi
      error = {:error, [%JsonApi.Error{}]}
      assert {:error, :timeout} = parse_responses([{:ok, error}, {:ok, %JsonApi{}}, {:ok, %JsonApi{}},
                                                   {:ok, %JsonApi{}}, {:ok, %JsonApi{}}, {:ok, %JsonApi{}}])
    end

    test "if they all complete, returns a %__MODULE__{} struct" do
      assert %HoursOfOperation{} = parse_responses([{:ok, %JsonApi{}}, {:ok, %JsonApi{}}, {:ok, %JsonApi{}},
                                                    {:ok, %JsonApi{}}, {:ok, %JsonApi{}}, {:ok, %JsonApi{}}])
    end

    test "returns min/max times if present, otherwise :no_service" do
      {min_item, min_time} = build_schedule()
      {max_item, max_time} = build_schedule()
      {only_item, only_time} = build_schedule()
      sunday_out_of_service = {:error, [%JsonApi.Error{code: "no_service"}]}
      responses = [
        {:ok, %JsonApi{data: [max_item, min_item]}},
        {:ok, %JsonApi{}},
        {:ok, sunday_out_of_service},
        {:ok, %JsonApi{}},
        {:ok, %JsonApi{data: [only_item]}},
        {:ok, %JsonApi{}}
      ]
      expected = %HoursOfOperation{
        week: {%Departures{first_departure: min_time, last_departure: max_time}, :no_service},
        saturday: {:no_service, %Departures{first_departure: only_time, last_departure: only_time}},
        sunday: {:no_service, :no_service}
      }
      actual = parse_responses(responses)
      assert expected == actual
    end
  end

  describe "join_hours/2" do
    test "returns a single struct" do
      assert join_hours([%HoursOfOperation{}]) == %HoursOfOperation{}
    end

    test "combines multiple structs, taking the earlier/latest times" do
      lower = DateTime.utc_now()
      middle = DateTime.utc_now()
      higher = DateTime.utc_now()
      lower_middle = %Departures{first_departure: lower, last_departure: middle}
      middle_higher = %Departures{first_departure: middle, last_departure: higher}
      lower_higher = %Departures{first_departure: lower, last_departure: higher}
      expected = %HoursOfOperation{
        week: {lower_higher, lower_higher},
        saturday: {lower_higher, lower_higher},
        sunday: {lower_higher, lower_higher}
      }
      actual = join_hours([
        %HoursOfOperation{
          week: {:no_service, lower_middle},
          saturday: {middle_higher, :no_service},
          sunday: {lower_middle, lower_middle}
        },
        %HoursOfOperation{},
        %HoursOfOperation{
          week: {lower_higher, middle_higher},
          saturday: {lower_middle, lower_higher},
          sunday: {middle_higher, middle_higher}
          }
      ])
      assert expected == actual
    end
  end

  describe "week_dates/1" do
    test "for a given date, returns the next monday, saturday, and sunday" do
      date = ~D[2017-10-26] # Thursday
      assert week_dates(date) == [
        ~D[2017-10-30], # Next Monday
        ~D[2017-10-28], # Upcoming Saturday
        ~D[2017-10-29] # Upcoming Sunday
      ]
    end

    test "on a sunday, we use the saturday from next week" do
      date = ~D[2017-10-29]
      assert week_dates(date) == [
        ~D[2017-10-30], # Next Monday
        ~D[2017-11-04], # Next Saturday
        date
      ]
    end

    test "always generates valid responses" do
      ptest date: date_vg(min_year: 2017) do
        [monday, saturday, sunday] = week_dates(date)
        assert Date.day_of_week(monday) == 1
        assert Date.day_of_week(saturday) == 6
        assert Date.day_of_week(sunday) == 7
      end
    end
  end

  describe "Enumerable" do
    test "returns items in week/saturday/sunday order, ignoring no-service dates" do
      hours = %HoursOfOperation{
        week: {:no_service, %Departures{}},
        saturday: {:no_service, :no_service},
        sunday: {%Departures{}, :no_service},
      }
      assert Enum.count(hours) == 2
      assert Enum.into(hours, []) == [week: hours.week, sunday: hours.sunday]
    end
  end

  defp date_vg(min_year: year) do
    year = int(min: year, max: year + 5)
    month = int(min: 1, max: 12)
    day = int(min: 1, max: 28)
    VG.struct(
      %Date{
        calendar: value(Calendar.ISO),
        year: year,
        month: month,
        day: day})
  end

  defp build_schedule do
    date_time = DateTime.utc_now()
    item = %JsonApi.Item{
      type: "schedule",
      attributes: %{
        "departure_time" => DateTime.to_iso8601(date_time)
      }}
    {item, date_time}
  end
end
