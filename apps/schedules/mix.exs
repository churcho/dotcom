defmodule Schedules.Mixfile do
  use Mix.Project

  def project do
    [app: :schedules,
     version: "0.0.1",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :v3_api, :timex, :repo_cache],
     mod: {Schedules, []}]
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
     {:timex, ">= 0.0.0"},
     {:repo_cache, in_umbrella: true},
     {:excheck, github: "paulswartz/excheck", ref: "bca297d", only: :test},
     {:triq, github: "krestenkrab/triq", only: :test},]
  end
end
