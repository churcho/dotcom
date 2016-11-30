defmodule Site.HowToPayView do
  use Site.Web, :view

  import Site.ViewHelpers

  alias Site.Components.Tabs.ModeTabList

  @spec mode_template(atom) :: String.t
  def mode_template(mode) do
    "#{mode}.html"
  end
end
