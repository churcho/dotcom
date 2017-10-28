defmodule Fares.Format do
  alias Fares.{Fare, Summary}

  @doc "Formats the price of a fare as a traditional $dollar.cents value"
  @spec price(Fare.t | non_neg_integer | nil) :: String.t
  def price(nil), do: ""
  def price(%Fare{cents: cents}) do
    price(cents)
  end
  def price(cents) do
    "$#{:erlang.float_to_binary(cents / 100, decimals: 2)}"
  end

  @doc "Formats the fare media (card, &c) as a string"
  @spec media(Fare.t | [Fare.media] | Fare.media) :: String.t
  def media(%Fare{media: list}), do: media(list)
  def media(list) when is_list(list) do
    list
    |> Enum.map(&media/1)
    |> Enum.join(" or ")
  end
  def media(:charlie_card), do: "CharlieCard"
  def media(:charlie_ticket), do: "CharlieTicket"
  def media(:commuter_ticket), do: "CharlieTicket"
  def media(:mticket), do: "mTicket App"
  def media(:cash), do: "Cash"
  def media(:senior_card), do: "Senior CharlieCard or TAP ID"
  def media(:student_card), do: "Student CharlieCard"

  @doc "Formats the customers that are served by the given fare: Adult / Student / Senior"
  @spec customers(Fare.t | Fare.reduced) :: String.t
  def customers(%Fare{reduced: reduced}), do: customers(reduced)
  def customers(:student), do: "Student"
  def customers(:senior_disabled), do: "Senior & Disabilities"
  def customers(nil), do: "Adult"

  @doc "Formats the duration of the Fare"
  @spec duration(Fare.t) :: String.t
  def duration(%Fare{duration: :single_trip}) do
    "One Way"
  end
  def duration(%Fare{duration: :round_trip}) do
    "Round Trip"
  end
  def duration(%Fare{name: :ferry_inner_harbor, duration: :day}) do
    "One-Day Pass"
  end
  def duration(%Fare{duration: :day}) do
    "Day Pass"
  end
  def duration(%Fare{duration: :week}) do
    "7-Day Pass"
  end
  def duration(%Fare{duration: :month, media: media}) do
    if :mticket in media do
      "Monthly Pass on mTicket App"
    else
      "Monthly Pass"
    end
  end

  @doc "Friendly name for the given Fare"
  @spec name(Fare.t | Fare.fare_name) :: String.t
  def name(%Fare{name: name}), do: name(name)
  def name(:subway), do: "Subway"
  def name(:local_bus), do: "Local Bus"
  def name(:inner_express_bus), do: "Inner Express Bus"
  def name(:outer_express_bus), do: "Outer Express Bus"
  def name(:ferry_inner_harbor), do: "Inner Harbor Ferry"
  def name(:ferry_cross_harbor), do: "Cross Harbor Ferry"
  def name(:commuter_ferry), do: "Commuter Ferry"
  def name(:commuter_ferry_logan), do: "Commuter Ferry to Logan Airport"
  def name({:zone, zone}), do: "Zone #{zone}"
  def name({:interzone, zone}), do: "Interzone #{zone}"
  def name(:foxboro), do: "Foxboro"

  @spec full_name(Fare.t) :: String.t | iolist
  def full_name(%Fare{mode: :subway, duration: :month}), do: "Monthly LinkPass"
  def full_name(%Fare{duration: :week}), do: "7-Day Pass"
  def full_name(%Fare{duration: :day}), do: "1-Day Pass"
  def full_name(%Fare{name: :ada_ride}), do: "ADA Ride"
  def full_name(%Fare{name: :premium_ride}), do: "Premium Ride"
  def full_name(fare) do
    [name(fare),
     " ",
     duration(fare)
    ]
  end

  @spec summarize([Fare.t], :bus_subway | :commuter_rail | :ferry, String.t | nil) :: [Summary.t]
  def summarize(fares, mode, url \\ nil)
  def summarize(fares, :bus_subway, url) do
    for [base|_] = chunk <- Enum.chunk_by(fares, &{&1.name, &1.duration, &1.additional_valid_modes}) do
      %Summary{
        name: Fares.Format.full_name(base),
        duration: base.duration,
        modes: [base.mode | base.additional_valid_modes],
        fares: Enum.map(chunk, &{Fares.Format.media(&1), Fares.Format.price(&1)}),
        url: url
      }
    end
  end
  def summarize(fares, mode, url) when mode in [:ferry, :commuter_rail] do
    for [base|_] = chunk <- Enum.chunk_by(fares, &match?(%{duration: :single_trip}, &1)) do
      price_range_label = price_range_label(mode)
      min_price = Enum.min_by(chunk, &(&1.cents))
      max_price = Enum.max_by(chunk, &(&1.cents))

      %Summary{
        name:  price_range_summary_name(base, mode),
        duration: base.duration,
        modes: [base.mode | base.additional_valid_modes],
        fares: [{price_range_label, [Fares.Format.price(min_price), " - ",
                                Fares.Format.price(max_price)]}],
        url: url}
    end
  end

  defp price_range_summary_name(fare, :commuter_rail), do: "Commuter Rail " <> duration(fare)
  defp price_range_summary_name(fare, :ferry), do: "Ferry " <> duration(fare)

  defp price_range_label(:commuter_rail), do: "Zones 1A-10"
  defp price_range_label(:ferry), do: "All Ferry routes"

  @spec summarize_one(Fare.t, Keyword.t) :: Summary.t
  def summarize_one(fare, opts \\ []) do
    %Fares.Summary{
      name: Fares.Format.full_name(fare),
      duration: fare.duration,
      modes: [fare.mode | fare.additional_valid_modes],
      fares: [{Fares.Format.media(fare), Fares.Format.price(fare.cents)}],
      url: Keyword.get(opts, :url)
    }
  end
end
