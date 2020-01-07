defmodule NatsPlayground.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: NatsPlayground.Worker.start_link(arg)
      # {NatsPlayground.Worker, arg}
      {NatsPlayground.Demo, []},
      {Stan, [name: Stan, client_id: client_id(), connection_settings: %{host: '127.0.0.1', port: 4223}]},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NatsPlayground.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp client_id do
    node() |> to_string() |> String.replace(["@", "."], "_")
  end
end
