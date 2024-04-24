defmodule Kobrakai.MixProject do
  use Mix.Project

  def project do
    [
      app: :kobrakai,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Kobrakai.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.0"},
      {:hero_icons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:nimble_publisher, "~> 1.0"},
      {:makeup_elixir, ">= 0.0.0"},
      {:makeup_erlang, ">= 0.0.0"},
      {:makeup_html, ">= 0.0.0"},
      {:makeup_eex, ">= 0.0.0"},
      {:yaml_elixir, "~> 2.9"},
      {:redirect, "~> 0.4.0"},
      {:image, "~> 0.44.0"},
      {:atomex, "~> 0.5.0"},
      {:etag_plug, "~> 1.0"},
      {:ecto, "~> 3.9"},
      {:phoenix_ecto, "~> 4.4"},
      {:bandit, "~> 1.0"},
      {:phoenix_storybook, "~> 0.6.0"},
      {:plug_cache_control, "~> 1.1.0", github: "tanguilp/plug_cache_control"},
      {:thumbor_path, github: "LostKobrakai/thumbor_path"},
      {:reverse_proxy_plug, "~> 2.1"},
      {:quantum, "~> 3.0"},
      {:vix, "~> 0.24.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "tailwind storybook", "esbuild default"],
      "assets.deploy": [
        "images.compile",
        "tailwind default --minify",
        "tailwind storybook --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end

  defp releases do
    [
      kobrakai: [
        steps: [:assemble, :tar]
      ]
    ]
  end
end
