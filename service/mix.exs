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
      # gleam libraries are linked to any pre 1.x version likely to have breaking changes
      # so we pin stdlib to all < 0.13 | 1.0
      {:gleam_stdlib, "~> 0.14.0", override: true},
      {:gleam_otp, "~> 0.1.4", override: true},
      {:earmark, "~> 1.4"},
      {:gleam_cowboy, "~> 0.2.2"},
      {:gleam_bitwise, "~> 1.0"},
      {:gleam_crypto, "~> 0.2"},
      {:gleam_http, "~> 2.0", override: true},
      {:gleam_httpc, "~> 1.0", override: true},
      {:gleam_json, "~> 0.1.0"},
      {:gleam_pgo, "~> 0.1.1"},
      {:gleam_sentry, "~> 0.1.1"},
      {:perimeter, github: "midas-framework/perimeter"}
    ]
  end
end
