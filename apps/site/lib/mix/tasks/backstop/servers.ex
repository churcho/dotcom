defmodule Backstop.Servers do
  require Logger
  use GenServer

  @callback environment() :: [{charlist, charlist}]
  @callback command() :: String.t
  @callback started_match() :: String.t
  @callback error_match() :: String.t | Regex.t
  @optional_callbacks environment: 0

  @type await_fn :: ((pid) -> :started | :error | :timeout)

  defmodule State do
    @type t :: %__MODULE__{
      module: atom,
      parent: pid,
      port: port
    }
    defstruct [:module, :parent, :port]
  end

  alias Backstop.Servers.State

  def await(pid) do
    receive do
      {^pid, :started} -> :started
      {^pid, :error} -> :error
    after
      :timer.seconds(600) -> # 10 minute timeout
        :timeout
    end
  end

  @doc "Shut down the given server"
  @spec shutdown(pid) :: :ok
  def shutdown(pid) do
    try do
      :ok = GenServer.stop(pid, :normal, 60_000)
    catch # if the process is already dead, return ok
      :exit, :noproc -> :ok
    end
  end

  @impl true
  def init([module, parent]) do
    port = Port.open(
      {:spawn, module.command()},
      [
        :stderr_to_stdout,
        line: 65_536,
        cd: directory(),
        env: module.environment()
      ])

    _ = Logger.info [server_name(module), " started with pid ", inspect self()]

    {:ok, %State{module: module,
                 parent: parent,
                 port: port}}
  end

  @impl true
  def terminate(reason, %{port: port} = state) do
    _ = Logger.info "shutting down #{server_name(state.module)}"
    :ok = kill_port(port)
    true = try do
             Port.close(port)
           rescue
             ArgumentError -> true
           end
    reason
  end

  @impl true
  def handle_info({port, {:data, {_flag, data_list}}}, %{module: module, port: port} = state) do
    data = :erlang.iolist_to_binary(data_list)
    _ = Logger.info [server_name(module), " => ", data_list]
    if data =~ apply(module, :started_match, []) do
      send_parent(state, :started)
    end
    if data =~ apply(module, :error_match, []) do
      send_parent(state, :error)
    end
    {:noreply, state}
  end

  @spec send_parent(State.t, atom) :: :ok
  defp send_parent(%{parent: parent}, message) do
    send parent, {self(), message}
  end

  @spec server_name(atom) :: String.t
  defp server_name(module) do
    module
    |> Module.split
    |> List.last
  end

  @spec kill_port(port) :: :ok
  defp kill_port(port) do
    case Port.info(port, :os_pid) do
      {:os_pid, pid} ->
        _ = System.cmd("kill", [Integer.to_string(pid)], stderr_to_stdout: true)
        :ok
      nil -> :ok
    end
  end

  defp directory do
    :site
    |> Application.app_dir
    |> String.replace("_build/#{Mix.env}/lib", "apps")
  end


  defmacro __using__([]) do
    quote do
      @behaviour unquote(__MODULE__)

      def start_link do
        GenServer.start_link(unquote(__MODULE__), [__MODULE__, self()])
      end

      def environment do
        []
      end

      defoverridable [environment: 0]
    end
  end
end

defmodule Backstop.Servers.Phoenix do
  @moduledoc "Run the Phoenix server."

  use Backstop.Servers

  @impl true
  def environment do
    [
      {'MIX_ENV', 'prod'},
      {'PORT', '8082'},
      {'STATIC_SCHEME', 'http'},
      {'STATIC_HOST', 'localhost'},
      {'STATIC_PORT', '8082'},
      {'V3_URL', 'http://localhost:8080'}
    ]
  end

  @impl true
  def command do
    "mix do deps.compile --force, compile --no-deps-check --force, phoenix.server"
  end

  @impl true
  def started_match do
    "Running Site.Endpoint"
  end

  @impl true
  def error_match do
    ~r/\[error\] (?!Supervisor|Could not find static manifest)/
  end
end

defmodule Backstop.Servers.Wiremock do
  @moduledoc "Run the Wiremock server."

  use Backstop.Servers

  @impl true
  def command do
    "java -jar #{Application.get_env(:site, :wiremock_path)}"
  end

  @impl true
  def started_match do
    "8080"
  end

  @impl true
  def error_match do
    ~r/(Address already in use)|(Unable to access jarfile)/
  end
end

defmodule Backstop.Servers.Helpers do
  import Backstop.Servers
  alias Mix.Tasks.Backstop.Tests
  require Logger

  @doc "Runs a given fn once the server pids have started.  Returns a status code."
  @spec run_with_pids([pid], %{String.t => String.t}, Tests.runner_fn,
                                                      Backstop.Servers.await_fn) :: {non_neg_integer, [pid]}
  def run_with_pids(pids, args, runner_fn \\ &Tests.run_backstop/1, await_fn \\ &await/1) do
    expected = Enum.map(pids, fn _ -> :started end)
    status = case Enum.map(pids, await_fn) do
               ^expected -> runner_fn.(args)
               _ -> 1
             end
    {status, pids}
  end
end
