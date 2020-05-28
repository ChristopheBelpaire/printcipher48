defmodule Printcipher48.MixProject do
  use Mix.Project

  def project do
    [
      app: :printcipher48,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/ChristopheBelpaire/printcipher48"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
    ]
  end

  defp description do
    "Implementation of the printcipher48 crypto algorithm in elixir."
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/ChristopheBelpaire/printcipher48"}
    ]
  end
end
