defmodule Alice.Music.Supervisor do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Alice.Music.AuthStore, []),
      Plug.Adapters.Cowboy.child_spec(:http, Alice.Music.AuthServer, [], [port: port(4000)])
    ]

    opts = [strategy: :one_for_one, name: Alice.Music.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp port(default) do
    (System.get_env("PORT") || "#{default}")
    |> String.to_integer
  end
end
