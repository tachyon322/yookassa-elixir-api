defmodule Yookassa.MixProject do
  use Mix.Project

  def project do
    [
      app: :yookassa,
      version: "0.1.3",
      # Recommend setting to ~> 1.14 for broader compatibility
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # --- Publication Settings ---

      # 1. Package description for Hex.pm
      description: "An Elixir client for the YooKassa API v3.",

      # 2. Main package configuration for Hex.
      package: [
        # Specify which files to include in the package.
        # NOTE: The `config` directory is excluded, so your keys will not be published.
        files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
        maintainers: ["tachyon322"],
        # Ensure you have a LICENSE file with the MIT license text.
        licenses: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/tachyon322/yookassa-elixir-api",
          "YooKassa API Docs" => "https://yookassa.ru/developers/api"
        }
      ],

      # 3. Documentation generation settings (for `mix docs`)
      docs: [
        # The main module to start documentation from.
        main: "Yookassa",
        source_url: "https://github.com/tachyon322/yookassa-elixir-api",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.4"},
      {:jason, "~> 1.4"},
      {:uuid, "~> 1.1"},
      {:plug_cowboy, "~> 2.7"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
