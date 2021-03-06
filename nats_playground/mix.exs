defmodule NatsPlayground.MixProject do
  use Mix.Project

  def project do
    [
      app: :nats_playground,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {NatsPlayground.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gnat, "~> 0.7.0"},
      {:protobuf, "~> 0.7.0"},
      {:google_protos, "~> 0.1.0"}
    ]
  end
end
