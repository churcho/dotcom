defmodule Services do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Services.Repo
    ]

    opts = [strategy: :one_for_one, name: Services.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
