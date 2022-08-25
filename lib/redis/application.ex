defmodule Redis.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling:
    Redis.Worker.start_link(arg),
      # {Redis.Worker, arg}
    Redis.Kv
    {Task, fn -> Redis.Server.accept(String.to_integer(System.get_env("PORT") || "6379")) end}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Redis.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
