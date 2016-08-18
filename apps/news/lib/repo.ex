defmodule News.Repo.Directory do
  def post_dir do
    config_dir = Application.fetch_env!(:news, :post_dir)
    case config_dir do
      <<"/", _::binary>> -> config_dir
      _ -> Application.app_dir(:news, config_dir)
    end
  end
end

defmodule News.Repo do
  @post_filenames News.Repo.Directory.post_dir
  |> File.ls!

  # compiled in, so basically there shouldn't be a TTL. Instead, we TTL for a
  # year.
  use RepoCache, ttl: :timer.hours(24 * 365)
  import Logger

  def all(opts \\ []) do
    cache opts, fn opts ->
      case Keyword.get(opts, :limit, :infinity) do
        :infinity ->
          do_all(@post_filenames)
        limit when is_integer(limit) ->
          @post_filenames
          |> Enum.sort
          |> Enum.reverse
          |> Enum.take(limit)
          |> do_all
      end
    end
  end

  def get!(_, id) do
    @post_filenames
    |> Enum.filter(&(String.contains?(&1, id)))
    |> do_all
    |> Enum.filter(&(&1.id == id))
    |> List.first
  end

  defp do_all(filenames) do
    filenames
    |> Enum.map(&(Path.join(News.Repo.Directory.post_dir, &1)))
    |> Enum.map(&Path.expand/1)
    |> Enum.map(&News.Jekyll.parse_file/1)
    |> Enum.filter_map(
    fn
      {:ok, _} -> true
      {:error, err} ->
        Logger.debug("error in news entry: #{inspect err}")
        false
    end,
    fn {:ok, parsed} -> parsed end)
  end

end
