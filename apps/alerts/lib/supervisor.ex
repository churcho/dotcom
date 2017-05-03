defmodule Alerts.Supervisor do
  @moduledoc """
  Supervisor for the alert app's caching processes. One worker is a process
  that maintans a few ETS tables, and the other worker is a process that periodically
  hits an API and updates the store.

  The supervision strategy is rest for one - if the fetcher crashes, restart it, but leave
  the ETS tables alone. If the ETS process crashes, restart it all.
  """

  use Supervisor

  @api_fn Application.get_env(:alerts, :api_fn)

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_arg) do
    children = [
      worker(Alerts.Cache.Store, []),
      worker(Alerts.Cache.Fetcher, [[api_fn: @api_fn]])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
