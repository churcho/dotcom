defmodule Routes.RouteTest do
  use ExUnit.Case, async: true
  alias Routes.Route
  import Route

  describe "type_atom/1" do
    test "returns an atom for the route type" do
      for {int, atom} <- [
        {0, :subway},
        {1, :subway},
        {2, :commuter_rail},
        {3, :bus},
        {4, :ferry}
      ] do
        assert type_atom(int) == atom
      end
    end

    test "handles hyphen in commuter-rail" do
      assert type_atom("commuter-rail") == :commuter_rail
      assert type_atom("commuter_rail") == :commuter_rail
    end

    test "extracts the type integer from the route struct and returns the corresponding atom" do
      assert type_atom(%Route{type: 3}) == :bus
    end
  end

  describe "icon_atom/1" do
    test "for subways, returns the name of the line as an atom" do
      for {expected, id} <- [
            red_line: "Red",
            mattapan_trolley: "Mattapan",
            orange_line: "Orange",
            blue_line: "Blue",
            green_line: "Green",
            green_line: "Green-B"] do
          route = %Route{id: id}
          actual = icon_atom(route)
          assert actual == expected
      end
    end

    test "for other routes, returns an atom based on the type" do
      for {expected, type} <- [
            commuter_rail: 2,
            bus: 3,
            ferry: 4] do
          route = %Route{type: type}
          actual = icon_atom(route)
          assert actual == expected
      end
    end
  end

  describe "types_for_mode/1" do
    test "returns correct mode list for each mode" do
      assert types_for_mode(:subway) == [0, 1]
      assert types_for_mode(:commuter_rail) == [2]
      assert types_for_mode(:bus) == [3]
      assert types_for_mode(:ferry) == [4]
    end
  end

  describe "type_name/1" do
    test "titleizes the name" do
      for {atom, str} <- [
        subway: "Subway",
        bus: "Bus",
        ferry: "Ferry",
        commuter_rail: "Commuter Rail",
        the_ride: "The Ride"
      ] do
        assert type_name(atom) == str
      end
    end

    test "handles hyphen in commuter-rail" do
      assert type_name("commuter-rail") == "Commuter Rail"
      assert type_name(:commuter_rail) == "Commuter Rail"
    end
  end

  describe "direction_name/2" do
    test "returns the name of the direction" do
      assert direction_name(%Route{}, 0) == "Outbound"
      assert direction_name(%Route{}, 1) == "Inbound"
      assert direction_name(%Route{direction_names: %{0 => "Zero"}}, 0) == "Zero"
    end
  end

  describe "vehicle_name/1" do
    test "returns the appropriate type of vehicle" do
      for {type, name} <- [
        {0, "Train"},
        {1, "Train"},
        {2, "Train"},
        {3, "Bus"},
        {4, "Ferry"},
      ] do
        assert vehicle_name(%Route{type: type}) == name
      end
    end
  end

  describe "key_route?" do
    test "extracts the :key_route? boolean" do
      assert key_route?(%Route{key_route?: true})
      refute key_route?(%Route{key_route?: false})
    end
  end

  describe "express routes" do
    defp sample(routes) do
      routes
      |> Enum.shuffle
      |> Enum.at(0)
      |> (fn id -> %Route{id: id} end).()
    end

    test "inner_express?/1 returns true if a route id is in @inner_express_routes" do
      assert inner_express?(sample(inner_express()))
      refute inner_express?(sample(outer_express()))
      refute inner_express?(%Route{id: "1"})
    end

    test "outer_express?/1 returns true if a route id is in @outer_express_routes" do
      assert outer_express?(sample(outer_express()))
      refute outer_express?(sample(inner_express()))
      refute outer_express?(%Route{id: "1"})
    end
  end

  describe "Phoenix.Param.to_param" do
    test "Green routes are normalized to Green" do
      green_e = %Route{id: "Green-E"}
      green_b = %Route{id: "Green-B"}
      green_c = %Route{id: "Green-C"}
      green_d = %Route{id: "Green-D"}
      to_param = &Phoenix.Param.Routes.Route.to_param/1
      for route <- [green_e, green_b, green_c, green_d] do
        assert to_param.(route) == "Green"
      end
    end

    test "Mattapan is kept as mattapan" do
      mattapan = %Route{id: "Mattapan"}
      assert Phoenix.Param.Routes.Route.to_param(mattapan) == "Mattapan"
    end
  end
end
