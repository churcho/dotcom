defmodule Site.ViewCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest
      import Phoenix.View
      import Site.Router.Helpers
      import Content.Factory
      import Site.ViewCaseHelper
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
