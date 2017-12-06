defmodule Util.AsyncAssign do
  @moduledoc """
  Utility for assigning in `Conn` asynchronously and setting defaults if the
  task times out.

  The functions in this module allow setting certain keys in `:assigns`
  asynchronously in a plug or controller with a defined fall-through behavior
  in the case of a time out or error.
  """

  require Logger
  alias Plug.Conn

  @doc """
  Starts a task to assign a value to a key in the connection and saves a default
  value.

  When `await_assign_default/2` is called, it will wait until the task completes and put
  that value under `key` in the `:assigns` field. If the task times out, then it
  will use `default`.

  The implementation is based on `Plug.Conn.async_assign/3`:
  https://github.com/elixir-plug/plug/blob/3d48af2b97d58c183a7b8390abc42ac5367b0770/lib/plug/conn.ex#L309
  """
  @spec async_assign_default(Conn.t, atom, (() -> term), term) :: Conn.t
  def async_assign_default(%Conn{} = conn, key, async_fn, default \\ nil)
  when is_atom(key) and is_function(async_fn, 0) do
    Conn.assign(conn, key, {Task.async(async_fn), default})
  end

  @doc """
  For all assigns that are Tasks with defaults, call await_assign_default/3.

  Returns a new `Conn` with all of the async keys in `:assigns` resolved.

  The implementation of this function and `await_assign_all_default/3` is based on
  `Plug.Conn.await_assign/3`:
  https://github.com/elixir-plug/plug/blob/3d48af2b97d58c183a7b8390abc42ac5367b0770/lib/plug/conn.ex#L332
  """
  @spec await_assign_all_default(Conn.t, timeout) :: Conn.t
  def await_assign_all_default(conn, timeout \\ 5000) do
    task_keys = for {key, {%Task{}, _}} <- conn.assigns do
      key
    end
    Enum.reduce(task_keys, conn, fn key, conn -> await_assign_default(conn, key, timeout) end)
  end

  @spec await_assign_default(Conn.t, atom, timeout) :: Conn.t
  defp await_assign_default(%Conn{} = conn, key, timeout) when is_atom(key) do
    {task, default} = Map.fetch!(conn.assigns, key)
    value = Util.yield_or_default(task, timeout, default)

    Conn.assign(conn, key, value)
  end
end
