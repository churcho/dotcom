defmodule Fares.RetailLocations.Location do
  defstruct [:agent,
             :city,
             :dates_sold,
             :hours_of_operation,
             :latitude,
             :longitude,
             :location,
             :method_of_payment,
             :name,
             :telephone,
             :type_of_passes_on_sale2007
            ]

  @type t :: %__MODULE__{ agent: String.t, city: String.t, dates_sold: String.t, hours_of_operation: String.t,
                          latitude: float, longitude: float, method_of_payment: String.t, name: String.t,
                          telephone: String.t, type_of_passes_on_sale2007: String.t}

  defimpl Util.Position do
    def latitude(%@for{latitude: latitude}), do: latitude
    def longitude(%@for{longitude: longitude}), do: longitude
  end
end
