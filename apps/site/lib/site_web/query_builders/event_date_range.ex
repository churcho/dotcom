defmodule SiteWeb.EventDateRange do
  @spec build(%{String.t() => String.t()}, Date.t()) :: map
  def build(%{"month" => month}, current_date) do
    case Date.from_iso8601(month) do
      {:ok, date} -> for_month(date)
      {:error, _error} -> for_month(current_date)
    end
  end

  def build(_month_missing, current_date) do
    for_month(current_date)
  end

  @spec for_month(Date.t()) :: map
  def for_month(date) do
    start_date = date |> Timex.beginning_of_month()
    end_date = date |> Timex.end_of_month() |> Timex.shift(days: 1)

    date_range(start_date: start_date, end_date: end_date)
  end

  defp date_range(start_date: start_date, end_date: end_date) do
    %{
      start_time_gt: start_date |> convert_to_iso_format,
      start_time_lt: end_date |> convert_to_iso_format
    }
  end

  defp convert_to_iso_format(date) do
    date |> Timex.format!("{ISOdate}")
  end
end
