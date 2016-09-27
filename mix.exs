defmodule Alice.Music.Mixfile do
  use Mix.Project

  def project do
    [app: :alice_music,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [
      applications: [:spotify_ex, :cowboy, :plug],
      mod: {Alice.Music.Supervisor, []}
    ]
  end

  defp deps do
    [
      {:websocket_client, github: "jeremyong/websocket_client"},
      {:alice,      "~> 0.3"},
      {:spotify_ex, "~> 2.0.1"},
      {:httpoison,  "~> 0.9.0", override: true},
      {:plug,       "~> 1.2"},
      {:cowboy,     "~> 1.0"}
    ]
  end
end
