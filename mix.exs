defmodule WwwRedirect.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/PJUllrich/www_redirect"

  def project do
    [
      app: :www_redirect,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :dev,
      deps: deps(),
      docs: docs(),
      package: package()
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
      {:phoenix, ">= 1.0.0"},
      {:plug, ">= 1.0.0"},
      {:igniter, ">= 0.6.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      description: "Redirects HTTP requests from WWW to Non-WWW and vice versa.",
      files: ["lib", "LICENSE", "mix.exs", "README.md"],
      licenses: ["MIT"],
      maintainers: ["Peter Ullrich"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md",
        "LICENSE"
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "main",
      formatters: ["html"]
    ]
  end
end
