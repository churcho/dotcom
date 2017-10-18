defmodule Alerts.InformedEntity do
  @fields [:route, :route_type, :stop, :trip, :direction_id]
  defstruct @fields
  @type t :: %Alerts.InformedEntity{
    route: String.t | nil,
    route_type: String.t | nil,
    stop: String.t | nil,
    trip: String.t | nil,
    direction_id: 0 | 1 | nil
  }

  alias __MODULE__, as: IE

  @doc """

  Given a keyword list (with keys matching our fields), returns a new
  InformedEntity.  Additional keys are ignored.

  """
  @spec from_keywords(list) :: %IE{}
  def from_keywords(options) do
    struct(__MODULE__, options)
  end

  @doc """

  Returns true if the two InformedEntities match.

  If a route/route_type/stop is specified (non-nil), it needs to equal the other.
  Otherwise the nil can match any value in the other InformedEntity.

  """
  @spec match?(%IE{}, %IE{}) :: boolean
  def match?(%IE{} = first, %IE{} = second) do
    share_a_key?(first, second) && do_match?(first, second)
  end

  defp do_match?(f, s) do
    @fields
    |> Enum.all?(&do_key_match(Map.get(f, &1), Map.get(s, &1)))
  end

  defp do_key_match(nil, _), do: true
  defp do_key_match(_, nil), do: true
  defp do_key_match(eql, eql), do: true
  defp do_key_match(_, _), do: false

  defp share_a_key?(first, second) do
    @fields
    |> Enum.any?(&shared_key(Map.get(first, &1), Map.get(second, &1)))
  end

  defp shared_key(nil, nil), do: false
  defp shared_key(eql, eql), do: true
  defp shared_key(_, _), do: false
end
