defmodule Util do
  use Timex

  @doc "joins two strings together, separating them with a space"
  def string_join(s1, s2)
  def string_join("", s2), do: s2
  def string_join(s1, ""), do: s1
  def string_join(s1, s2), do: s1 <> " " <> s2

  @doc "Given a list of values, return the one which appears the most"
  def most_frequent_value(values) do
    values
    |> Enum.group_by(&(&1))
    |> Enum.into([])
    |> Enum.max_by(fn {_, items} -> length(items) end)
    |> elem(0)
  end

  @doc "The current datetime in the America/New_York timezone."
  @spec now() :: DateTime.t
  @spec now((() -> DateTime.t)) :: DateTime.t
  def now(utc_now_fn \\ &Timex.now/0) do
    to_local_time(utc_now_fn.())
  end

  @doc "Today's date in the America/New_York timezone."
  def today do
    now() |> Timex.to_date
  end

  @doc "Converts a DateTime.t into the America/New_York zone, handling ambiguities"
  @spec to_local_time(DateTime.t) :: DateTime.t
  def to_local_time(time) do
    case Timex.Timezone.convert(time, "America/New_York") do
      %Timex.AmbiguousDateTime{before: before} -> before
      time -> time
    end
  end

  @doc """
  Converts an {:error, _} tuple to a default value.

  # Examples

    iex> Util.error_default(:value, :default)
    :value
    iex> Util.error_default({:error, :tuple}, :default)
    :default
  """
  @spec error_default(value | {:error, any}, value) :: value
  when value: any
  def error_default(error_or_default, default)
  def error_default({:error, _}, default) do
    default
  end
  def error_default(value, _default) do
    value
  end

  @doc """

  The current service date.  The service date lasts from 3am to 2:59am, so
  times after midnight belong to the service of the previous date.

  """
  def service_date(current_time \\ nil) do
    current_time = current_time || Util.now()

    current_time
    |> Timex.shift(hours: -3)
    |> Timex.to_date
  end

  @doc """

  Returns an id property in a struct or nil

  """
  def safe_id(%{id: id}), do: id
  def safe_id(nil), do: nil

  @doc "Interleaves two lists. Appends the remaining elements of the longer list"
  @spec interleave(list, list) :: list
  def interleave([h1|t1], [h2|t2]), do: [h1, h2 | interleave(t1, t2)]
  def interleave([], l), do: l
  def interleave(l, []), do: l
end
