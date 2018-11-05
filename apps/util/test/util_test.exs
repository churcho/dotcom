defmodule UtilTest do
  use ExUnit.Case, async: true
  use Quixir
  import Util
  doctest Util

  describe "now/1" do
    test "handles ambiguous UTC times by returning the earlier time" do
      for {time, expected} <- [
            {~N[2016-11-06T05:00:00], "2016-11-06T01:00:00-04:00"},
            {~N[2016-11-06T06:00:00], "2016-11-06T02:00:00-04:00"},
            {~N[2016-11-06T07:00:00], "2016-11-06T02:00:00-05:00"}
          ] do

          utc_fn = fn "America/New_York" -> Timex.set(time, timezone: "UTC") end
          assert utc_fn |> now() |> Timex.format("{ISO:Extended}") == {:ok, expected}
      end
    end
  end

  describe "to_local_time/1" do
    test "handles NaiveDateTime" do
      assert %DateTime{day: 02, hour: 0, zone_abbr: "EST"} = Util.to_local_time(~N[2016-01-02T05:00:00])
    end

    test "handles NaiveDateTime in EST -> EDT transition" do
      assert %DateTime{month: 3, day: 11, hour: 1, zone_abbr: "EST"} = Util.to_local_time(~N[2018-03-11T06:00:00])
      assert %DateTime{month: 3, day: 11, hour: 3, zone_abbr: "EDT"} = Util.to_local_time(~N[2018-03-11T07:00:00])
    end

    test "handles NaiveDateTime in EDT -> EST transition" do
      assert %DateTime{month: 11, day: 4, hour: 1, zone_abbr: "EDT"} = Util.to_local_time(~N[2018-11-04T05:00:00])
      assert %DateTime{month: 11, day: 4, hour: 2, zone_abbr: "EDT"} = Util.to_local_time(~N[2018-11-04T06:00:00])
      assert %DateTime{month: 11, day: 4, hour: 2, zone_abbr: "EST"} = Util.to_local_time(~N[2018-11-04T07:00:00])
    end

    test "handles DateTime in UTC timezone" do
      assert %DateTime{day: 02, hour: 0} = ~N[2016-01-02T05:00:00]
      |> DateTime.from_naive!("Etc/UTC")
      |> Util.to_local_time()
    end

    test "handles Timex.AmbiguousDateTime.t" do
      before_date = Util.to_local_time(~N[2018-11-04T05:00:00])
      after_date = Util.to_local_time(~N[2018-11-04T06:00:00])
      assert before_date == Util.to_local_time(%Timex.AmbiguousDateTime{after: after_date, before: before_date})
    end
  end

  describe "service_date/0" do
    test "returns the service date for the current time" do
      assert service_date() == service_date(now())
    end
  end

  describe "service_date/1 for NaiveDateTime" do
    test "returns the service date" do
      yesterday = ~D[2016-01-01]
      today = ~D[2016-01-02]

      midnight = ~N[2016-01-02T05:00:00]
      assert %DateTime{day: 02, hour: 0} = Util.to_local_time(midnight)
      assert Util.service_date(midnight) == yesterday

      one_am = ~N[2016-01-02T06:00:00]
      assert %DateTime{day: 02, hour: 1} = Util.to_local_time(one_am)
      assert Util.service_date(one_am) == yesterday

      two_am = ~N[2016-01-02T07:00:00]
      assert %DateTime{day: 02, hour: 2} = Util.to_local_time(two_am)
      assert Util.service_date(two_am) == yesterday

      three_am = ~N[2016-01-02T08:00:00]
      assert %DateTime{day: 02, hour: 3} = Util.to_local_time(three_am)
      assert Util.service_date(three_am) == today

      four_am = ~N[2016-01-02T09:00:00]
      assert %DateTime{day: 02, hour: 4} = Util.to_local_time(four_am)
      assert Util.service_date(four_am) == today
    end

    test "handles EST -> EDT transition" do
      assert Util.service_date(~N[2018-03-11T05:00:00]) == ~D[2018-03-10] # midnight EST
      assert Util.service_date(~N[2018-03-11T06:00:00]) == ~D[2018-03-10] # 1am EST
      assert Util.service_date(~N[2018-03-11T07:00:00]) == ~D[2018-03-11] # 2am EST / 3am EDT
      assert Util.service_date(~N[2018-03-11T08:00:00]) == ~D[2018-03-11] # 4am EDT
    end

    test "handles EDT -> EST transition" do
      assert Util.service_date(~N[2018-11-04T04:00:00]) == ~D[2018-11-03] # midnight EDT
      assert Util.service_date(~N[2018-11-04T05:00:00]) == ~D[2018-11-03] # 1am EDT
      assert Util.service_date(~N[2018-11-04T06:00:00]) == ~D[2018-11-03] # 2am EDT / 1am EST
      assert Util.service_date(~N[2018-11-04T07:00:00]) == ~D[2018-11-03] # 2am EST
      assert Util.service_date(~N[2018-11-04T08:00:00]) == ~D[2018-11-04] # 3am EST
      assert Util.service_date(~N[2018-11-04T09:00:00]) == ~D[2018-11-04] # 4am EST
    end
  end

  describe "service_date/1 for DateTime in America/New_York timezone" do
    test "returns the service date" do
      yesterday = ~D[2016-01-01]
      today = ~D[2016-01-02]

      assert ~N[2016-01-02T05:00:00] # 12am
             |> Util.to_local_time()
             |> Util.service_date() == yesterday

      assert ~N[2016-01-02T06:00:00] # 1am
             |> Util.to_local_time()
             |> Util.service_date() == yesterday

      assert ~N[2016-01-02T07:00:00] # 2am
             |> Util.to_local_time()
             |> Util.service_date() == yesterday

      assert ~N[2016-01-02T08:00:00] # 3am
             |> Util.to_local_time()
             |> Util.service_date() == today

      assert ~N[2016-01-02T09:00:00] # 4am
             |> Util.to_local_time()
             |> Util.service_date() == today
    end

    test "handles EST -> EDT transition" do
      assert ~N[2018-03-11T05:00:00] # midnight EST
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-03-10]
      assert ~N[2018-03-11T06:00:00] # 1am EST
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-03-10]
      assert ~N[2018-03-11T07:00:00] # 2am EST / 3am EDT
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-03-11]
      assert ~N[2018-03-11T08:00:00] # 4am EDT
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-03-11]
    end

    test "handles EDT -> EST transition" do
      assert ~N[2018-11-04T04:00:00] # midnight EDT
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-03]

      assert ~N[2018-11-04T05:00:00] # 1am EDT
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-03]

      assert ~N[2018-11-04T06:00:00] # 2am EDT / 1am EST
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-03]

      assert ~N[2018-11-04T07:00:00] # 2am EST
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-03]

      assert ~N[2018-11-04T08:00:00] # 3am EST
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-04]

      assert ~N[2018-11-04T09:00:00] # 4am EST
             |> Util.to_local_time()
             |> Util.service_date() == ~D[2018-11-04]
    end
  end

  describe "service_date/1 for DateTime in UTC timezone" do
    test "returns the service date" do
      yesterday = ~D[2016-01-01]
      today = ~D[2016-01-02]

      assert ~N[2016-01-02T05:00:00] # 12am
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == yesterday

      assert ~N[2016-01-02T06:00:00] # 1am
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == yesterday

      assert ~N[2016-01-02T07:00:00] # 2am
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == yesterday

      assert ~N[2016-01-02T08:00:00] # 3am
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == today

      assert ~N[2016-01-02T09:00:00] # 4am
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == today
    end

    test "handles EST -> EDT transition" do
      assert ~N[2018-03-11T05:00:00] # midnight EST
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-03-10]
      assert ~N[2018-03-11T06:00:00] # 1am EST
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-03-10]
      assert ~N[2018-03-11T07:00:00] # 2am EST / 3am EDT
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-03-11]
      assert ~N[2018-03-11T08:00:00] # 4am EDT
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-03-11]
    end

    test "handles EDT -> EST transition" do
      assert ~N[2018-11-04T04:00:00] # midnight EDT
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-03]

      assert ~N[2018-11-04T05:00:00] # 1am EDT
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-03]

      assert ~N[2018-11-04T06:00:00] # 2am EDT / 1am EST
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-03]

      assert ~N[2018-11-04T07:00:00] # 2am EST
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-03]

      assert ~N[2018-11-04T08:00:00] # 3am EST
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-04]

      assert ~N[2018-11-04T09:00:00] # 4am EST
             |> DateTime.from_naive!("Etc/UTC")
             |> Util.service_date() == ~D[2018-11-04]
    end
  end

  describe "interleave" do
    test "interleaves lists" do
      assert Util.interleave([1, 3, 5], [2, 4, 6]) == [1, 2, 3, 4, 5, 6]
    end

    test "handles empty lists" do
      assert Util.interleave([1, 2, 3], []) == [1, 2, 3]
      assert Util.interleave([], [1, 2, 3]) == [1, 2, 3]
    end

    test "handles lists of different lengths" do
      assert Util.interleave([1, 3], [2, 4, 5, 6]) == [1, 2, 3, 4, 5, 6]
      assert Util.interleave([1, 3, 5, 6], [2, 4]) == [1, 2, 3, 4, 5, 6]
    end
  end

  describe "async_with_timeout/3" do
    test "returns the value of a task if it ends in time" do
      assert async_with_timeout([fn -> 5 end, fn -> 6 end], nil, 1000) == [5, 6]
    end

    test "returns the default for a task that runs too long and logs a warning" do
      log = ExUnit.CaptureLog.capture_log(fn ->
        assert async_with_timeout([
          fn -> 5 end,
          fn -> :timer.sleep(60_000) end
        ], :default, 10) == [5, :default]
      end)
      assert log =~ "async task timed out"
    end
  end

  describe "yield_or_default_many/2" do
    test "returns result when task does not timeout, and default when it does" do
      short_fn = fn -> :task_result end
      long_fn = fn -> :timer.sleep(1_000) end
      aborted_task = Task.async(long_fn)
      task_map = %{
        Task.async(short_fn) => {:short, :short_default},
        Task.async(long_fn) => {:long, :long_default},
        aborted_task => {:aborted, :aborted_default}
      }
      Process.unlink(aborted_task.pid)
      Process.exit(aborted_task.pid, :kill)
      log = ExUnit.CaptureLog.capture_log(fn ->
        assert Util.yield_or_default_many(task_map, 500) == %{
          short: :task_result,
          long: :long_default,
          aborted: :aborted_default
        }
      end)
      assert log =~ "Returning: :long_default"
      assert log =~ "task exited unexpectedly"
      refute log =~ "Returning: :short_default"
    end
  end

  test "config/2 returns config values" do
    Application.put_env(:util, :config_test, {:system, "CONFIG_TEST", "default"})
    assert Util.config(:util, :config_test) == "default"
    System.put_env("CONFIG_TEST", "env")
    assert Util.config(:util, :config_test) == "env"
    System.delete_env("CONFIG_TEST")
    Application.delete_env(:util, :config_test)
  end

  test "config/2 doesn't raise if config isn't found" do
    assert Util.config(:util, :config_test) == nil
  end

  test "config/3 returns nested config values" do
    Application.put_env(:util, :config_test, nested: {:system, "CONFIG_TEST", "default"})
    assert Util.config(:util, :config_test, :nested) == "default"
    System.put_env("CONFIG_TEST", "env")
    assert Util.config(:util, :config_test, :nested) == "env"
    System.delete_env("CONFIG_TEST")
    Application.delete_env(:util, :config_test)
  end

  test "config/3 raises if config isn't found" do
    assert_raise ArgumentError, fn -> Util.config(:util, :config_test, :nested) end
  end
end
