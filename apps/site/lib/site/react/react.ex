defmodule Site.React do
  @moduledoc """
  React renderer supervisor
  """
  require Logger
  use Supervisor
  alias Phoenix.HTML

  @timeout 10_000
  @pool_name :react_render
  @default_pool_size 4

  @doc """
  Starts the react renderer worker pool.
  """
  @spec start_link() :: {:ok, pid} | {:error, any()}
  def start_link do
    opts = [pool_size: @default_pool_size]
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Stops the react renderer worker pool.
  """
  @spec stop() :: :ok
  def stop do
    Supervisor.stop(__MODULE__)
  end

  @spec render(String.t(), map) :: HTML.safe()
  def render(react_component_name, args) do
    case do_render(react_component_name, args) do
      {:ok, %{"markup" => body}} ->
        HTML.raw(body)

      {:error, %{"error" => %{"message" => message}}} ->
        _ = Logger.warn(fn -> "react_renderer component=#{react_component_name} #{message}" end)
        ""
    end
  end

  defp do_render(component, props) do
    task =
      Task.async(fn ->
        :poolboy.transaction(
          @pool_name,
          fn pid -> GenServer.call(pid, {:render, component, props}) end,
          :infinity
        )
      end)

    Task.await(task, @timeout)
  end

  @doc """
  Initialize the pool supervisor
  """
  def init(opts) do
    config = Application.get_env(:site, :react)

    :ok = dev_build(config[:source_path])

    pool_size = Keyword.fetch!(opts, :pool_size)

    pool_opts = [
      name: {:local, @pool_name},
      worker_module: Site.React.Worker,
      size: pool_size,
      max_overflow: 0
    ]

    children = [
      :poolboy.child_spec(@pool_name, pool_opts)
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end

  def dev_build(path, cmd_fn \\ &System.cmd/3)
  def dev_build(nil, _), do: :ok

  def dev_build(path, cmd_fn) do
    {_, 0} =
      cmd_fn.(
        "npx",
        ["webpack"],
        cd: path
      )

    :ok
  end
end
