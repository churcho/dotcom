defmodule Site.TripPlan.DateTime do
  alias Site.TripPlan.Query

  @type time_type :: :depart_at | :arrive_by
  @type date_error :: :invalid_date | {:too_future, DateTime.t()} | {:past, DateTime.t()}
  @type date_time :: {time_type, DateTime.t()} | {:error, date_error}

  @spec validate(Query.t(), map, Keyword.t()) :: Query.t()
  def validate(%Query{} = query, %{"date_time" => dt} = params, opts) do
    {:ok, now} = Keyword.fetch(opts, :now)
    {:ok, end_of_rating} = Keyword.fetch(opts, :end_of_rating)
    type = get_departure_type(params)

    dt
    |> parse()
    |> future_date_or_error(now)
    |> verify_inside_rating(end_of_rating)
    |> round_minute()
    |> do_validate(type, query)
  end

  def validate(%Query{} = query, params, opts) do
    {:ok, now} = Keyword.fetch(opts, :now)
    validate(query, Map.put(params, "date_time", now), opts)
  end

  @spec do_validate(DateTime.t() | {:error, any}, String.t() | nil, Query.t()) :: Query.t()
  defp do_validate({:error, {error, %DateTime{} = dt}}, type, query)
       when error in [:too_future, :past] do
    errors = MapSet.put(query.errors, error)
    do_validate(dt, type, %{query | errors: errors})
  end

  defp do_validate({:error, error}, _, query) when is_atom(error) do
    %{query | time: {:error, error}, errors: MapSet.put(query.errors, error)}
  end

  defp do_validate(%DateTime{} = dt, "depart", query) do
    %{query | time: {:depart_at, dt}}
  end

  defp do_validate(%DateTime{} = dt, "arrive", query) do
    %{query | time: {:arrive_by, dt}}
  end

  @spec parse(map) :: {:ok, NaiveDateTime.t()} | {:error, any}
  defp parse(date_params) do
    case date_to_string(date_params) do
      <<str::binary>> ->
        str
        |> Timex.parse("{YYYY}-{M}-{D} {_h24}:{_m} {AM}")
        |> do_parse()

      error ->
        error
    end
  end

  defp do_parse({:ok, %NaiveDateTime{} = naive}) do
    if Timex.is_valid?(naive) do
      naive
    else
      {:error, :invalid_date}
    end
  end

  defp do_parse({:error, _}), do: {:error, :invalid_date}

  defp date_to_string(%{
         "year" => year,
         "month" => month,
         "day" => day,
         "hour" => hour,
         "minute" => minute,
         "am_pm" => am_pm
       }) do
    "#{year}-#{month}-#{day} #{hour}:#{minute} #{am_pm}"
  end

  defp date_to_string(%DateTime{} = date) do
    date
  end

  defp date_to_string(%{}) do
    {:error, :invalid_date}
  end

  @spec future_date_or_error(NaiveDateTime.t() | {:error, :invalid_date}, DateTime.t()) ::
          date_time
  defp future_date_or_error({:error, :invalid_date}, %DateTime{}) do
    {:error, :invalid_date}
  end

  defp future_date_or_error(%DateTime{} = now, %DateTime{} = system_dt) do
    do_future_date_or_error(now, system_dt)
  end

  defp future_date_or_error(%NaiveDateTime{} = naive_dt, %DateTime{} = system_dt) do
    naive_dt
    |> Timex.to_datetime(system_dt.time_zone)
    |> handle_ambiguous_time()
    |> do_future_date_or_error(system_dt)
  end

  @spec do_future_date_or_error(DateTime.t(), DateTime.t()) ::
          DateTime.t() | {:error, {:past, DateTime.t()}}
  defp do_future_date_or_error(%DateTime{} = input, %DateTime{} = now) do
    if Timex.before?(input, now) do
      {:error, {:past, input}}
    else
      input
    end
  end

  @spec handle_ambiguous_time(DateTime.t() | Timex.AmbiguousDateTime.t()) :: DateTime.t()
  defp handle_ambiguous_time(%DateTime{} = dt) do
    dt
  end

  defp handle_ambiguous_time(%Timex.AmbiguousDateTime{before: before}) do
    # if you select a date/time during the DST transition, the service
    # will still be running under the previous timezone. Therefore, we
    # pick the "before" time which is n the original zone.
    before
  end

  defp verify_inside_rating({:error, error}, %Date{}) do
    {:error, error}
  end

  defp verify_inside_rating(%DateTime{} = dt, %Date{} = end_of_rating) do
    dt
    |> Util.service_date()
    |> Date.compare(end_of_rating)
    |> case do
      :gt -> {:error, {:too_future, dt}}
      _ -> dt
    end
  end

  @doc """
  Takes a DateTime and rounds it to the next round 5 minute interval.
  """
  @spec round_minute(DateTime.t() | {:error, any}) :: DateTime.t() | {:error, any}
  def round_minute(%DateTime{} = dt) do
    dt.minute
    |> Integer.mod(5)
    |> case do
      0 -> dt
      mod -> Timex.shift(dt, minutes: 5 - mod)
    end
  end

  def round_minute({:error, error}) do
    {:error, error}
  end

  @spec get_departure_type(map) :: String.t()
  defp get_departure_type(params) do
    case Map.get(params, "time") do
      "arrive" -> "arrive"
      _ -> "depart"
    end
  end
end
