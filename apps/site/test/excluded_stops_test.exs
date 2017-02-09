defmodule ExcludedStopsTest do
  use ExUnit.Case, async: true
  import ExcludedStops

  describe "excluded_origin_stops/3" do
    test "excludes the last stop on a non-Red or Green line" do
      all_stops = Enum.map(1..10, & %{id: Integer.to_string(&1)})

      assert excluded_origin_stops(0, "Route", all_stops) == ["10"]
    end

    test "excludes both terminals on southbound Red Line trips" do
      assert excluded_origin_stops(0, "Red", []) == ["place-brntn", "place-asmnl"]
    end

    test "excludes last terminal on northbound Red Line trips" do
      all_stops = Enum.map(1..10, & %{id: Integer.to_string(&1)})

      assert excluded_origin_stops(1, "Red", all_stops) == ["10"]
    end

    test "if no stops are passed, returns the empty list" do
      assert excluded_origin_stops(1, "Route", []) == []
    end

    test "excludes all terminals on westbound Green Line trips" do
      assert excluded_origin_stops(0, "Green", []) == ["place-lake", "place-clmnl", "place-river", "place-hsmnl"]
    end

    test "excludes Lechmere on eastbound GL trips" do
      all_stops = 1
      |> GreenLine.stops_on_routes
      |> GreenLine.all_stops

      assert excluded_origin_stops(1, "Green", all_stops) == ["place-lech"]
    end
  end

  describe "excluded_destination_stops/2" do
    test "excludes nothing for non-Red or Green lines" do
      assert excluded_destination_stops("Green-B", "place-pktrm") == []
    end

    test "excludes Ashmont stops if the origin is on the Braintree branch" do
      assert "place-smmnl" in excluded_destination_stops("Red", "place-brntn")
    end

    test "excludes Braintree stops if the origin is on the Ashmont branch" do
      assert "place-qamnl" in excluded_destination_stops("Red", "place-asmnl")
    end

    test "excludes stops on different branches of the consolidated Green Line" do
      assert "place-prmnl" in excluded_destination_stops("Green", "place-lake")
      assert "place-bland" in excluded_destination_stops("Green", "place-clmnl")
      assert "place-smary" in excluded_destination_stops("Green", "place-river")
      assert "place-fenwy" in excluded_destination_stops("Green", "place-hsmnl")
      assert "place-spmnl" in excluded_destination_stops("Green", "place-hymnl")
    end
  end
end
