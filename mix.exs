defmodule Kobrakai.MixProject do
  use Mix.Project

  def project do
    [
      app: :kobrakai,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      listeners: [Phoenix.CodeReloader],
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
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:hero_icons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:bun, "~> 2.0", runtime: Mix.env() == :dev},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:nimble_publisher, "~> 1.0"},
      {:makeup_elixir, ">= 0.0.0"},
      {:makeup_erlang, ">= 0.0.0"},
      {:makeup_html, ">= 0.0.0"},
      {:makeup_eex, ">= 0.0.0"},
      {:yaml_elixir, "~> 2.9"},
      {:redirect, "~> 0.4.0"},
      {:image, "~> 0.67.0"},
      {:atomex, "~> 0.5.0"},
      {:etag_plug, "~> 1.0"},
      {:ecto, "~> 3.9"},
      {:phoenix_ecto, "~> 4.5"},
      {:bandit, "~> 1.0"},
      {:phoenix_storybook, "~> 1.0"},
      {:plug_cache_control, "~> 1.1.0", github: "tanguilp/plug_cache_control"},
      {:thumbor_path, github: "LostKobrakai/thumbor_path"},
      {:reverse_proxy_plug, "~> 3.0"},
      {:quantum, "~> 3.0"},
      {:extrace, "~> 0.5"},
      {:dns_cluster, "~> 0.2.0"},
      {:req, "~> 0.5.0"},
      {:phoenix_bakery, "~> 1.0", runtime: false},
      {:oidcc_plug, "~> 0.4.0"},
      # https://github.com/elixir-plug/plug/pull/1302
      {:plug, "~> 1.19.1",
       github: "LostKobrakai/plug",
       ref: "f25ffe856e12e5d4eaf0c6f22504cc538796c398",
       override: true},
      {:zoneinfo, "~> 0.1.0"},
      {:localize, "~> 0.25.0"},
      {:localize_web, "~> 0.5.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    colored_mix = "elixir --erl \"-elixir\\ ansi_enabled\\ true\" -S mix"

    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["bun.install --if-missing", "bun install"],
      "assets.build": ["bun default", "bun css", "bun storybook", "bun serviceworker"],
      "assets.deploy": [
        "images.compile",
        "bun default --minify",
        "bun css --minify",
        "bun storybook --minify",
        "phx.digest",
        "bun serviceworker --minify"
      ],
      checks: [
        "cmd #{colored_mix} deps.unlock --check-unused",
        "cmd #{colored_mix} compile --force --warnings-as-errors",
        "cmd #{colored_mix} xref graph --format cycles --label compile-connected --fail-above 0",
        "cmd #{colored_mix} format --check-formatted",
        "cmd #{colored_mix} gettext.extract --check-up-to-date"
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
