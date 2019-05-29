defmodule Content.CMS.HTTPClient do
  @moduledoc """

  Performs composition of external requests to CMS API.

  """

  alias Content.ExternalRequest

  @behaviour Content.CMS

  @impl true
  def preview(node_id, revision_id) do
    path = ~s(/cms/revisions/#{node_id})

    ExternalRequest.process(
      :get,
      path,
      "",
      params: [_format: "json", vid: revision_id],
      # More time needed to lookup revision (CMS filters through ~50 revisions)
      timeout: 10_000,
      recv_timeout: 10_000
    )
  end

  @impl true
  def view(path, params) do
    params = [
      {"_format", "json"}
      | Enum.reduce(params, [], &stringify_params/2)
    ]

    ExternalRequest.process(:get, path, "", params: params)
  end

  @type param_key :: String.t() | atom()
  @type param_value :: String.t() | atom() | Keyword.t()
  @type param_list :: [{String.t(), String.t()}]

  # Allow only whitelisted, known, nested params
  @type safe_key :: :value | :min | :max
  @safe_keys [:value, :min, :max]

  @spec stringify_params({param_key, param_value}, param_list) :: param_list
  defp stringify_params({key, val}, acc) when is_atom(key) do
    stringify_params({Atom.to_string(key), val}, acc)
  end

  defp stringify_params({key, val}, acc) when is_atom(val) do
    stringify_params({key, Atom.to_string(val)}, acc)
  end

  defp stringify_params({key, val}, acc) when is_integer(val) do
    stringify_params({key, Integer.to_string(val)}, acc)
  end

  defp stringify_params({key, val}, acc) when is_binary(key) and is_binary(val) do
    [{key, val} | acc]
  end

  defp stringify_params({key, val}, acc) when is_binary(key) and is_list(val) do
    val
    # drop original param, add new key/vals for nested params
    |> Enum.reduce(acc, fn nested_param, acc -> list_to_params(key, acc, nested_param) end)
    # restore original order of nested params
    |> Enum.reverse()
  end

  defp stringify_params(_, acc) do
    # drop invalid param
    acc
  end

  # Convert nested key values to their own keys, if whitelisted
  @spec list_to_params(String.t(), param_list, {safe_key(), String.t()}) :: param_list
  defp list_to_params(key, acc, {sub_key, sub_val}) when sub_key in @safe_keys do
    stringify_params({key <> "[#{sub_key}]", sub_val}, acc)
  end

  defp list_to_params(_, acc, _) do
    # drop invalid param
    acc
  end
end
