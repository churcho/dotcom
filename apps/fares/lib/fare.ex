defmodule Fares.Fare do
  @typedoc """

  Represents a method of paying for transit on the MBTA.

  """
  @type fare_name :: {atom, String.t()} | atom
  @type media :: :charlie_card
               | :charlie_ticket
               | :cash
               | :commuter_ticket
               | :mticket
               | :student_card
               | :senior_card
  @type reduced :: nil | :student | :senior_disabled
  @type duration :: :single_trip | :round_trip | :day | :week | :month | :invalid
  @type t :: %__MODULE__{
    mode: Routes.Route.route_type,
    name: fare_name,
    media: [media],
    reduced: reduced,
    duration: duration,
    cents: non_neg_integer,
    additional_valid_modes: [Routes.Route.route_type]
  }

  defstruct [
    mode: nil,
    name: nil,
    media: [],
    reduced: nil,
    duration: nil,
    cents: 0,
    additional_valid_modes: []
  ]
end
