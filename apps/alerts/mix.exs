defmodule Alerts.Mixfile do
  use Mix.Project

  def project do
    [app: :alerts,
     version: "0.0.1",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :timex, :repo_cache, :con_cache, :tzdata],
      mod: {Alerts, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:v3_api, in_umbrella: true},
     {:repo_cache, in_umbrella: true},
     {:con_cache, "~> 0.12.0"},
     {:timex, ">= 0.0.0"},
     {:util, in_umbrella: true, only: :test},
     {:quixir, "~> 0.9", only: :test},
     {:excoveralls, "~> 0.5", only: :test},
     {:benchfella, "~> 0.3", only: :dev}]
  end
end
