defmodule Fares.FareInfoTest do
  use ExUnit.Case, async: true
  alias Fares.Fare
  import Fares.FareInfo

  describe "fare_info/0" do
    test "returns a non-empty list of Fare objects" do
      actual = fare_info()
      refute actual == []
      assert Enum.all?(actual, &match?(%Fare{}, &1))
    end
  end

  describe "mapper/1" do
    test "maps the fares for a zone into one-way and round trip tickets, and monthly ticket and mticket prices" do
      assert mapper(["commuter", "zone_1a", "2.25", "1.10", "84.50"]) == [
               %Fare{
                 name: {:zone, "1A"},
                 mode: :commuter_rail,
                 duration: :single_trip,
                 media: [:commuter_ticket, :cash, :mticket],
                 reduced: nil,
                 cents: 225
               },
               %Fare{
                 name: {:zone, "1A"},
                 mode: :commuter_rail,
                 duration: :single_trip,
                 media: [:student_card],
                 reduced: :student,
                 cents: 110
               },
               %Fare{
                 name: {:zone, "1A"},
                 mode: :commuter_rail,
                 duration: :single_trip,
                 media: [:senior_card],
                 reduced: :senior_disabled,
                 cents: 110
               },
               %Fare{
                 name: {:zone, "1A"},
                 mode: :commuter_rail,
                 duration: :round_trip,
                 media: [:commuter_ticket, :cash, :mticket],
                 reduced: nil,
                 cents: 450
               },
               %Fare{
                 name: {:zone, "1A"},
                 mode: :commuter_rail,
                 duration: :round_trip,
                 media: [:student_card],
                 reduced: :student,
                 cents: 220
               },
               %Fare{
                 name: {:zone, "1A"},
                 mode: :commuter_rail,
                 duration: :round_trip,
                 media: [:senior_card],
                 reduced: :senior_disabled,
                 cents: 220
               },
               %Fare{
                 name: {:zone, "1A"},
                 mode: :commuter_rail,
                 duration: :month,
                 media: [:commuter_ticket],
                 reduced: nil,
                 cents: 8450,
                 additional_valid_modes: [:subway, :bus, :ferry]
               },
               %Fare{
                 name: {:zone, "1A"},
                 mode: :commuter_rail,
                 duration: :month,
                 media: [:mticket],
                 reduced: nil,
                 cents: 7450
               }
             ]
    end

    test "does not include subway or ferry modes for interzone fares" do
      assert mapper(["commuter", "interzone_5", "4.50", "2.25", "148.00"]) == [
               %Fares.Fare{
                 additional_valid_modes: [],
                 cents: 450,
                 duration: :single_trip,
                 media: [:commuter_ticket, :cash, :mticket],
                 mode: :commuter_rail,
                 name: {:interzone, "5"},
                 reduced: nil
               },
               %Fares.Fare{
                 additional_valid_modes: [],
                 cents: 225,
                 duration: :single_trip,
                 media: [:student_card],
                 mode: :commuter_rail,
                 name: {:interzone, "5"},
                 reduced: :student
               },
               %Fares.Fare{
                 additional_valid_modes: [],
                 cents: 225,
                 duration: :single_trip,
                 media: [:senior_card],
                 mode: :commuter_rail,
                 name: {:interzone, "5"},
                 reduced: :senior_disabled
               },
               %Fares.Fare{
                 additional_valid_modes: [],
                 cents: 900,
                 duration: :round_trip,
                 media: [:commuter_ticket, :cash, :mticket],
                 mode: :commuter_rail,
                 name: {:interzone, "5"},
                 reduced: nil
               },
               %Fares.Fare{
                 additional_valid_modes: [],
                 cents: 450,
                 duration: :round_trip,
                 media: [:student_card],
                 mode: :commuter_rail,
                 name: {:interzone, "5"},
                 reduced: :student
               },
               %Fares.Fare{
                 additional_valid_modes: [],
                 cents: 450,
                 duration: :round_trip,
                 media: [:senior_card],
                 mode: :commuter_rail,
                 name: {:interzone, "5"},
                 reduced: :senior_disabled
               },
               %Fares.Fare{
                 additional_valid_modes: [:bus],
                 cents: 14_800,
                 duration: :month,
                 media: [:commuter_ticket],
                 mode: :commuter_rail,
                 name: {:interzone, "5"},
                 reduced: nil
               },
               %Fares.Fare{
                 additional_valid_modes: [],
                 cents: 13_800,
                 duration: :month,
                 media: [:mticket],
                 mode: :commuter_rail,
                 name: {:interzone, "5"},
                 reduced: nil
               }
             ]
    end
  end

  describe "grouped_fares/1" do
    grouped_fare_data = grouped_fares()
    assert is_list(grouped_fare_data)
  end

  describe "mticket_price/1" do
    test "subtracts 10 dollars from the monthly price" do
      assert mticket_price(2000) == 1000
    end
  end

  describe "floor_to_ten_cents/1" do
    test "floors to nearest ten cents" do
      assert floor_to_ten_cents(949) == 940
      assert floor_to_ten_cents(944) == 940
    end
  end
end
