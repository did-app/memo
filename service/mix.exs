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
      extra_applications: [:logger],
      mod: {PlumMail.Application, []}
    ]
  end

  defp deps do
    [
      {:mix_gleam, "~> 0.1.0"},
      {:gleam_cowboy, github: "gleam-experiments/cowboy", manager: :rebar3, branch: :main}
    ]
  end
end
