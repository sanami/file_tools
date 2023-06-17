defmodule FileTools.MixProject do
  use Mix.Project

  def project do
    [
      app: :file_tools,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {FileTools.Application, []}
    ]
  end

  defp aliases do
    [
      run: "run_no_halt"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:csv, "~> 3.0"},
    ]
  end
end
