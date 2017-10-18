defmodule Alerts.Match do
  @moduledoc """

  Returns the alerts which match the provided InformedEntity or entities.

  Passing multiple entities will allow the matching to be more efficient.

  """
  use Timex

  alias Alerts.InformedEntity, as: IE
  def match(alerts, entity, datetime \\ nil)
  def match(alerts, entity, nil) do
    for alert <- alerts,
      any_entity_match?(alert, entity) do
        alert
    end
  end
  def match(alerts, entity, datetime) do
    # time first in order to minimize the more-expensive entity match
    for alert <- alerts,
      any_time_match?(alert, datetime),
      any_entity_match?(alert, entity) do
        alert
    end
  end

  defp any_entity_match?(alert, entities) when is_list(entities) do
    alert.informed_entity
    |> Enum.any?(fn ie ->
      entities
      |> Enum.any?(&IE.match?(ie, &1))
    end)
  end
  defp any_entity_match?(alert, entity) do
    alert.informed_entity
    |> Enum.any?(&IE.match?(entity, &1))
  end

  def any_time_match?(alert, datetime) do
    alert.active_period
    |> Enum.any?(&between?(&1, datetime))
  end

  defp between?({nil, nil}, _) do
    true
  end
  defp between?({start, nil}, datetime) do
    not Timex.before?(datetime, start)
  end
  defp between?({nil, stop}, datetime) do
    not Timex.after?(datetime, stop)
  end
  defp between?({start, stop}, datetime) do
    Timex.between?(datetime, start, stop) ||
      Timex.equal?(datetime, start) ||
      Timex.equal?(datetime, stop)
  end
end
