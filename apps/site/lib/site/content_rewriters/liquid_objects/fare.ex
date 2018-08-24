defmodule Site.ContentRewriters.LiquidObjects.Fare do
  @moduledoc """

  This module converts a string-based set of fare filters to a proper keyword list request
  intended for Fares.Repo.all/1, and parses the price of the final result into a string.

  IMPORTANT: Any atom changes in the Fares.Fare module need to also be made here, and should
  likewise be updated in the Content team's online legend for fare replacement usage here:
  https://docs.google.com/spreadsheets/d/18DGY0es_12xy54oDE9lDTJwATx4jhodWkND7MuY7R6E?pli=1#gid=1197832395

  """

  alias Fares.{Fare, Format, Repo, Summary}

  # Fares.Fare related type specs
  @type required_key :: :reduced | :duration
  @type optional_key :: :name | :mode | :includes_media
  @type summary_mode :: :commuter_rail | :bus_subway | :ferry
  @type the_ride :: :ada_ride | :premium_ride
  @type fare_name :: :commuter_ferry_logan | :commuter_ferry | :ferry_cross_harbor | :ferry_inner_harbor |
                     :foxboro | :inner_express_bus | :local_bus | :outer_express_bus | :subway

  @type fare_key :: optional_key | required_key
  @type fare_value :: fare_name | the_ride | summary_mode | Fare.media | Fare.reduced | Fare.duration
  @type request_error :: {:error, {:invalid | :empty | :incomplete | :unmatched, String.t}}
  @type fares_or_summaries :: [Summary.t] | Summary.t | [Fare.t] | Fare.t
  @type repo_arg :: {fare_key, fare_value}

  @default_args [reduced: nil, duration: :single_trip]
  @summary_atoms [:commuter_rail, :bus_subway, :ferry]

  @fare_summary [
    "commuter_rail",
    "bus_subway",
    "ferry"
  ]

  @fare_name [
    "commuter_ferry_logan",
    "commuter_ferry",
    "ferry_cross_harbor",
    "ferry_inner_harbor",
    "foxboro",
    "inner_express_bus",
    "local_bus",
    "outer_express_bus",
    "subway"
  ]

  @fare_ride [
    "ada_ride",
    "premium_ride"
  ]

  @fare_media [
    "cash",
    "charlie_card",
    "charlie_ticket",
    "commuter_ticket",
    "mticket"
  ]

  @fare_reduced [
    "senior_disabled",
    "student",
    "nil"
  ]

  @fare_duration [
    "day",
    "week",
    "month",
    "single_trip",
    "round_trip"
  ]

  @spec fare_request(String.t) :: {:ok, String.t} | request_error
  def fare_request(string) do
    string
    |> String.split(":", trim: true)
    |> parse_tokens()
    |> compose_args()
    |> request_fares()
    |> process_results()
  end

  @spec parse_tokens([String.t]) :: {:ok, [repo_arg]} | request_error
  defp parse_tokens(new), do: parse_tokens(new, [], [])

  @spec parse_tokens([String.t], [repo_arg], [String.t]) :: {:ok, [repo_arg]} | request_error
  defp parse_tokens(_, _, [token]) do
    {:error, {:invalid, token}}
  end
  defp parse_tokens([], filters, _) do
    {:ok, filters}
  end
  defp parse_tokens([string | remaining_strings], good, bad) do
    {valid, invalid} =  parse_token(string, good, bad)
    parse_tokens(remaining_strings, valid, invalid)
  end

  @spec parse_token(String.t, [repo_arg], [String.t]) :: {[repo_arg], [String.t]}
  defp parse_token(value, good, bad) when value in @fare_summary do
    {filter_insert(good, mode: value), bad}
  end
  defp parse_token(value, good, bad) when value in @fare_name do
    {filter_insert(good, name: value), bad}
  end
  defp parse_token(value, good, bad) when value in @fare_ride do
    {filter_insert(good, name: value, reduced: "senior_disabled"), bad}
  end
  defp parse_token(value, good, bad) when value in @fare_media do
    {filter_insert(good, includes_media: value), bad}
  end
  defp parse_token(value, good, bad) when value in @fare_reduced do
    {filter_insert(good, reduced: value), bad}
  end
  defp parse_token(value, good, bad) when value in @fare_duration do
    {filter_insert(good, duration: value), bad}
  end
  defp parse_token(value, good, bad) do
    {good, [value | bad]}
  end

  @spec compose_args({:ok, list} | request_error) ::
    {:ok, [repo_arg] | {summary_mode, [repo_arg]}} | request_error
  defp compose_args({:ok, []}) do
    {:error, {:empty, "no input"}}
  end
  defp compose_args({:ok, args}) do
    case Enum.into(args, %{}) do
      # Prevent both :mode and :name keys from being sent to Repo.all (never matches fare)
      %{name: _} -> {:ok, Keyword.delete(args, :mode)}
      # When using a :mode, the summarize/3 function requires an explicit :mode argument
      %{mode: mode} -> {:ok, {mode, args}}
      # If there is neither a :mode nor a :name key/value, we cannot perform the request
      _ -> {:error, {:incomplete, "missing mode/name"}}
    end
  end
  defp compose_args(invalid_error), do: invalid_error

  @spec request_fares({:ok, [repo_arg] | {summary_mode, [repo_arg]}} | request_error) ::
    [Summary.t] | [Fare.t] | request_error
  defp request_fares({:ok, {mode, args}}) when mode in @summary_atoms do
    args
    |> get_fares()
    |> Format.summarize(mode)
  end
  defp request_fares({:ok, args}), do: get_fares(args)
  defp request_fares(error), do: error

  @spec process_results(fares_or_summaries | request_error) :: {:ok, String.t} | request_error
  defp process_results([]) do
    {:error, {:unmatched, "no results"}}
  end
  defp process_results([first_result | _]) do
    process_results(first_result)
  end
  defp process_results(%Fares.Fare{} = fare) do
    {:ok, Format.price(fare)}
  end
  defp process_results(%Fares.Summary{} = summary) do
    {:ok, Summary.price_range(summary)}
  end
  defp process_results(error), do: error

  # Helpers

  # Fill in any missing/required arguments with the default,
  # then call Fares.Repo.all/1 to get matching fares.
  @spec get_fares([repo_arg]) :: [Fare.t]
  defp get_fares(args) do
    @default_args
    |> Keyword.merge(args)
    |> Repo.all()
  end

  # Adds the valid key/val into our arg list, after first
  # converting the value into a proper, known Fare atom.
  @spec filter_insert([repo_arg], [{fare_key, String.t | atom}]) :: [repo_arg]
  defp filter_insert(old_args, new_args) do
    Enum.reduce(new_args, old_args, fn {k, v}, args ->
      Keyword.put(args, k, String.to_existing_atom(v))
    end)
  end
end
