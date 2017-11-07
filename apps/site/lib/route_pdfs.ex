defmodule Site.RoutePdfs do
  @moduledoc """
  gets pdfs for a route from the CMS, and chooses which ones to display
  """

  alias Content.RoutePdf

  @spec fetch_and_choose_pdfs(String.t, Date.t) :: [RoutePdf.t]
  def fetch_and_choose_pdfs(route_id, date) do
    route_id
    |> Content.Repo.get_route_pdfs
    |> choose_pdfs(date)
  end

  @spec choose_pdfs([RoutePdf.t], Date.t) :: [RoutePdf.t]
  def choose_pdfs(route_pdfs, date) do
    {custom, basic} = Enum.split_with(route_pdfs, &RoutePdf.custom?/1)
    choose_basic_pdfs(basic, date) ++ choose_custom_pdfs(custom, date)
  end

  @spec choose_custom_pdfs([RoutePdf.t], Date.t) :: [RoutePdf.t]
  defp choose_custom_pdfs(route_pdfs_with_custom_text, date) do
    route_pdfs_with_custom_text
    |> Enum.reject(&RoutePdf.outdated?(&1, date))
    |> Enum.filter(&RoutePdf.started?(&1, date))
  end

  @spec choose_basic_pdfs([RoutePdf.t], Date.t) :: [RoutePdf.t]
  defp choose_basic_pdfs(route_pdfs, date) do
    {current, upcoming} = route_pdfs
    |> Enum.reject(&RoutePdf.outdated?(&1, date))
    |> sort_by_date
    |> Enum.split_with(&RoutePdf.started?(&1, date))
    chosen_current = case List.last(current) do
      nil -> []
      most_recent -> [most_recent]
    end
    chosen_upcoming = case List.first(upcoming) do
      nil -> []
      next -> [next]
    end
    chosen_current ++ chosen_upcoming
  end

  @spec sort_by_date([RoutePdf.t]) :: [RoutePdf.t]
  defp sort_by_date(route_pdfs) do
    #head is ealier, tail is later
    Enum.sort(route_pdfs, &Date.compare(&1.date_start, &2.date_start) == :lt)
  end
end
