defmodule Acx.MixProject do
  use Mix.Project

  def project do
    [
      app: :acx,
      version: "0.1.1",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Acx, []}
    ]
  end

  # specifies which paths to compile per environment
  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.10"},
      {:ecto_psql_extras, "~> 0.8"},
      {:ecto_autoslug_field, "~> 3.1"},
      {:ecto_enum, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  def docs() do
    # See https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
    [
      # The main page in the docs
      main: "Acx",
      extras: [
        "README.md"
      ],
      # output: "priv/static/docs",
      authors: [
        "korczis@gmail.com"
      ],
      formatters: [
        "html",
        "epub"
      ]
    ]
  end
end
