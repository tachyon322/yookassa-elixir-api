defmodule Yookassa.MixProject do
  use Mix.Project

  def project do
    [
      app: :yookassa,
      version: "0.1.1",
      # Рекомендую снизить до ~> 1.14 для большей совместимости
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # --- НИЖЕ ИДУТ ДОБАВЛЕНИЯ ДЛЯ ПУБЛИКАЦИИ ---

      # 1. Описание пакета, которое будет видно на Hex.pm
      description: "An Elixir client for the YooKassa API v3.",

      # 2. Главная секция для публикации.
      package: [
        # Указываем, какие файлы попадут в пакет.
        # ВАЖНО: папки `config` здесь нет, поэтому ваши ключи останутся у вас.
        files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
        # <-- ЗАМЕНИТЕ ЭТО
        maintainers: ["tachyon322"],
        # Убедитесь, что у вас есть файл LICENSE с текстом лицензии MIT
        licenses: ["MIT"],
        links: %{
          # <-- ЗАМЕНИТЕ ЭТО
          "GitHub" => "https://github.com/tachyon322/yookassa-elixir-api",
          "YooKassa API Docs" => "https://yookassa.ru/developers/api"
        }
      ],

      # 3. Настройки для генерации документации (mix docs)
      docs: [
        # Главный модуль, с которого начнется документация
        main: "Yookassa",
        # <-- И ЭТО ТОЖЕ
        source_url: "https://github.com/tachyon322/yookassa-elixir-api",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
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
