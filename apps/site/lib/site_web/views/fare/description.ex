defmodule SiteWeb.FareView.Description do
  alias Fares.Fare
  import Phoenix.HTML.Tag, only: [content_tag: 2]
  import Util.AndJoin

  @spec description(Fare.t, map()) :: Phoenix.HTML.unsafe
  def description(%Fare{mode: :commuter_rail, duration: :single_trip, name: name}, _assigns) do
    ["Valid for travel on Commuter Rail ", valid_commuter_zones(name), " only."]
  end
  def description(%Fare{mode: :commuter_rail, duration: :round_trip, name: name}, _assigns) do
    ["Valid for travel on Commuter Rail ", valid_commuter_zones(name), " only."]
  end
  def description(%Fare{mode: :commuter_rail, duration: :month, media: [:mticket], name: name}, _assigns) do
    ["Valid for one calendar month of travel on the commuter rail ",
     valid_commuter_zones(name),
     " only."
    ]
  end
  def description(%Fare{mode: :commuter_rail, duration: :month, additional_valid_modes: [:bus], name: name}, _assigns) do
    ["Valid for one calendar month of unlimited travel on Commuter Rail ",
     valid_commuter_zones(name),
     " as well as Local Bus."]
  end
  def description(%Fare{mode: :commuter_rail, duration: :month, name: name}, _assigns) do
    ["Valid for one calendar month of unlimited travel on Commuter Rail ",
     valid_commuter_zones(name),
     " as well as Local Bus, Subway, and the Charlestown Ferry."]
  end
  def description(%Fare{mode: :ferry, duration: duration}, %{origin: origin, destination: destination}) when duration in [:round_trip, :single_trip, :day, :week] do
    [
      "Valid between ",
      origin.name,
      " and ",
      destination.name,
      " only."
    ]
  end
  def description(%Fare{mode: :ferry, duration: duration} = fare, _assigns) when duration in [:round_trip, :single_trip, :day, :week] do
    [
      "Valid for the ",
      Fares.Format.name(fare),
      " only."
    ]
  end
  def description(%Fare{mode: :ferry, duration: :month, media: [:mticket]} = fare, _assigns) do
       [
         "Valid for one calendar month of unlimited travel on the ",
         Fares.Format.name(fare),
         " only."
       ]
  end
  def description(%Fare{mode: :ferry, duration: :month} = fare, _assigns) do
    [
      "Valid for one calendar month of unlimited travel on the ",
      Fares.Format.name(fare),
      " as well as the Local Bus, \
 Subway, Express Buses, and Commuter Rail up to Zone 5."
    ]
  end
  def description(%Fare{name: name, duration: :single_trip, media: [:charlie_ticket, :cash]}, _assigns)
  when name in [:inner_express_bus, :outer_express_bus] do
    "No free or discounted transfers."
  end
  def description(%Fare{mode: :subway, media: media, duration: :single_trip} = fare, _assigns)
  when media != [:charlie_ticket, :cash] do

    [
      "Valid for all Subway lines (includes Routes SL1 and SL2). ",
      transfers(fare),
      " Must be done within 2 hours of your original ride."
    ]
  end
  def description(%Fare{mode: :subway, media: [:charlie_ticket, :cash]}, _assigns) do
    "Free transfer to Subway, Route SL4, and Route SL5 when done within 2 hours of purchasing a ticket."
  end
  def description(%Fare{mode: :bus, media: [:charlie_ticket, :cash]}, _assigns) do
    "Free transfer to one additional Local Bus included."
  end
  def description(%Fare{mode: :subway, duration: :month, reduced: :student}, _assigns) do
    modes = ["Local Bus", "Subway", "Commuter Rail Zone 1A (CharlieTicket only)"]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for 1 calendar month on:"),
     content_tag(:ul, modes)
    ]
  end
  def description(%Fare{mode: :subway, duration: :month}, _assigns) do
    modes = ["Local Bus", "Subway", "Commuter Rail Zone 1A (CharlieTicket only)"]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for 1 calendar month on:"),
     content_tag(:ul, modes)
    ]
  end
  def description(%Fare{mode: :subway, duration: duration}, _assigns) when duration in [:day, :week] do
    modes = ["Local Bus", "Subway", "Commuter Rail Zone 1A (CharlieTicket only)", "Charlestown Ferry (CharlieTicket only)"]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for #{duration_string_header(duration)}* on:"),
     content_tag(:ul, modes),
     "*CharlieTickets are valid for ",
     duration_string_body(duration),
     " from purchase. CharlieCards are valid for ",
     duration_string_body(duration),
     " after first use."
    ]
  end
  def description(%Fare{name: :local_bus, duration: :month}, _assigns) do
    modes = ["Local Bus (not including routes SL1 and SL2)"]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for 1 calendar month on:"),
     content_tag(:ul, modes)
    ]
  end
  def description(%Fare{name: :inner_express_bus, media: [:charlie_card, :charlie_ticket], duration: :month}, _assigns) do
    modes = ["Inner Express Bus", "Local Bus", "Subway",
             "Commuter Rail Zone 1A (CharlieTicket or pre-printed CharlieCard with valid date only)",
             "Charlestown Ferry (CharlieTicket or pre-printed CharlieCard with valid date only)"]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for 1 calendar month on:"),
     content_tag(:ul, modes)
    ]

  end
  def description(%Fare{name: :inner_express_bus, duration: :month}, _assigns) do
    ["Unlimited travel for one calendar month on the Inner Express Bus",
     "Local Bus",
     "Subway."
    ] |> and_join
  end
  def description(%Fare{name: :outer_express_bus, media: [:charlie_card, :charlie_ticket], duration: :month}, _assigns) do
    modes = ["Outer Express Bus", "Inner Express Bus", "Local Bus", "Subway",
             "Commuter Rail Zone 1A (CharlieTicket or pre-printed CharlieCard with valid date only)",
             "Charlestown Ferry (CharlieTicket or pre-printed CharlieCard with valid date only)"
            ]
            |> Enum.map(&content_tag(:li, &1))

    [content_tag(:div, "Unlimited travel for 1 calendar month on:"),
     content_tag(:ul, modes)
    ]
  end
  def description(%Fare{name: :outer_express_bus, duration: :month}, _assigns) do
    ["Unlimited travel for one calendar month on the Outer Express Bus as well as the Inner Express Bus",
     "Local Bus",
     "Subway.",
    ] |> and_join
  end
  def description(%Fare{name: :free_fare, mode: :bus, media: []}, _assigns) do
    ["Valid for the Local Bus (includes Route SL4 and SL5)."]
  end
  def description(%Fare{mode: :bus, media: media} = fare, _assigns)
  when media != [:charlie_ticket, :cash] do
    [
      "Valid for the Local Bus (includes Route SL4 and SL5). ",
      transfers(fare),
      " Must be done within 2 hours of your original ride."
    ]
  end
  def description(%Fare{name: :ada_ride}, _assigns) do
    ["A trip qualifies as ADA if it is booked 1-7 days beforehand. ",
     "It must also be within 3/4 miles from an active MBTA Bus or Subway service, or be in the core ADA area."]
  end
  def description(%Fare{name: :premium_ride}, _assigns) do
    ["A trip qualifies as premium if it has been booked for same-day service or if a reservation has been changed after 5:00P for service the next day.",
     "<br><br>" |> Phoenix.HTML.raw,
     "A trip also qualifies if it is not within the core ADA area of service, or has a destination more than 3/4 miles away from an active MBTA Bus or Subway service."
    ]
  end
  def description(%Fare{name: :free_fare}, _assigns) do
    ["Inbound SL1 travel from any airport stop is free."]
  end

  defp duration_string_body(:day), do: "24 hours"
  defp duration_string_body(:week), do: "7 days"

  defp duration_string_header(:day), do: "1 day"
  defp duration_string_header(:week), do: "7 days"

  defp valid_commuter_zones({:zone, "1A"}) do
    "in Zone 1A only"
  end
  defp valid_commuter_zones({:zone, final}) do
    ["from Zones 1A-", final]
  end
  defp valid_commuter_zones({:interzone, total}) do
    ["between ", total, " zones outside of Zone 1A"]
  end
  defp valid_commuter_zones(:foxboro) do
    "to Gillette Stadium for special events"
  end

  def transfers(fare) do
    # used to generate the list of transfer fees for a a given fare.
    # Transfers <= 0 are considered free.
    {paid, free} = [subway: "Subway",
                    local_bus: "Local Bus",
                    inner_express_bus: "Inner Express Bus",
                    outer_express_bus: "Outer Express Bus"]
                    |> Enum.split_with(&transfers_filter(&1, fare))
    [
      free_transfers(free),
      Enum.map(paid, &transfers_map(&1, fare))
    ]
  end

  defp transfers_filter({name, _}, fare) do
    other_fare = transfers_other_fare(name, fare)
    other_fare.cents > fare.cents
  end

  defp free_transfers([]) do
    []
  end
  defp free_transfers(names_and_texts) do
    ["Free transfers to ",
     names_and_texts
     |> Enum.map(&elem(&1, 1))
     |> and_join,
     "."
    ]
  end

  defp transfers_map({name, text}, fare) do
    other_fare = transfers_other_fare(name, fare)
    [" Transfer to ", text, ": ", Fares.Format.price(other_fare.cents - fare.cents), "."]
  end

  defp transfers_other_fare(name, fare) do
    case {fare, name, Fares.Repo.all(name: name, media: fare.media, duration: fare.duration)} do
      {_, _, [other_fare]} -> other_fare
    end
  end
end
