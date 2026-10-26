defmodule KapsoEx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/rocket4ce/kaspo_ex"

  def project do
    [
      app: :kapso_ex,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description:
        "Elixir client for the Kapso API (WhatsApp, Platform, Workflows and Kapso Agent).",
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:req, "~> 0.7.5"},
      {:jason, "~> 1.4"},
      {:mime, "~> 2.0"},
      {:plug, "~> 1.16", optional: true},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url, "Kapso docs" => "https://docs.kapso.ai"}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md"],
      groups_for_modules: [
        Core: [KapsoEx, KapsoEx.Client, KapsoEx.Error, KapsoEx.Pagination],
        WhatsApp: ~r/^KapsoEx\.WhatsApp/,
        Platform: ~r/^KapsoEx\.Platform/,
        "Workflows & Functions": [
          KapsoEx.Workflows,
          KapsoEx.Workflows.Executions,
          KapsoEx.Workflows.Triggers,
          KapsoEx.Functions
        ],
        "Kapso Agent": ~r/^KapsoEx\.Agent/,
        Webhooks: ~r/^KapsoEx\.Webhook/
      ]
    ]
  end
end
