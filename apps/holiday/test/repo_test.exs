defmodule Holiday.RepoTest do
  use ExUnit.Case, async: true

  describe "all/0" do
    test "returns a list of Holidays" do
      actual = Holiday.Repo.all

      assert actual != []
      assert Enum.all?(actual, &match?(%Holiday{}, &1))
    end
  end

  describe "by_date/1" do
    test "returns Christmas Day on 2016-12-25" do
      date = ~D[2018-12-25]
      assert Holiday.Repo.by_date(date) ==
        [%Holiday{date: date, name: "Christmas Day"}]
    end

    test "returns Veterans Day (Observed) on 2018-11-12" do
      date = ~D[2018-11-12]
      assert Holiday.Repo.by_date(date) ==
        [%Holiday{date: date, name: "Veterans’ Day (Observed)"}]
    end

    test "returns nothing for 2018-11-01" do
      date = ~D[2016-11-01]
      assert Holiday.Repo.by_date(date) == []
    end
  end

  describe "holidays_in_month/1" do
    test "returns all holidays in the given month" do
      for date <- [~D[2016-12-01], ~D[2016-12-25], ~D[2016-12-31]] do
        assert Holiday.Repo.holidays_in_month(date) == [
          %Holiday{date: ~D[2016-12-25], name: "Christmas Day"},
          %Holiday{date: ~D[2016-12-26], name: "Christmas Day (Observed)"}
        ]
      end
    end
  end
end

defmodule Holiday.Repo.HelpersTest do
  use ExUnit.Case, async: true
  doctest Holiday.Repo.Helpers
end
