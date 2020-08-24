defmodule PlumMail.MixProject do
  use Mix.Project

  def project do
    [
      app: :plum_mail,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      erlc_paths: ["src", "gen"],
      compilers: [:gleam | Mix.compilers()],
      deps: deps()
    ]
  end

  def application do
    [
      # NOTE gleam_http should be required by cowboy
      extra_applications: [:logger, :gleam_http],
      mod: {PlumMail.Application, []}
    ]
  end

  defp deps do
    [
      {:mix_gleam, "~> 0.1.0"},
      {:gleam_cowboy, github: "gleam-experiments/cowboy", manager: :rebar3, branch: :main},
      {:gleam_json, "~> 0.1.0"}
    ]
  end
end
