defmodule Alice.Music.AuthStore do
  def start_link do
    Agent.start_link(fn -> %Spotify.Credentials{} end, name: __MODULE__)
  end

  def get_auth do
    Agent.get(__MODULE__, &(&1))
  end

  def put_auth(auth) do
    Agent.update(__MODULE__, fn(_old) -> auth end)
  end

  def clear_auth do
    put_auth(%Spotify.Credentials{})
  end
end
