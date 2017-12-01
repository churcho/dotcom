defmodule Content.CMS do
  @moduledoc """
  The behaviour for a live HTTP or a static testing API over our content CMS.
  """

  @doc """
  Issues a request for a given path, with optional parameters
  for the request. Parses the JSON result but does not do anything
  beyond that. Shouldn't raise an exception; if the HTTP request
  or JSON decoding fails, returns {:error, message}
  """
  @callback view(String.t, Keyword.t) :: {:ok, list(map())} | {:ok, map()} | {:error, String.t}
  @callback preview(String.t, String.t) :: {:ok, list(map())} | {:ok, map()} | {:error, String.t}
  @callback post(String.t, String.t) :: {:ok, Poison.Parser.t} | {:error, map} | {:error, String.t}
  @callback update(String.t, String.t) :: {:ok, Poison.Parser.t} | {:error, map} | {:error, String.t}
end
