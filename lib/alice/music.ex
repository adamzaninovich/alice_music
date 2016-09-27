defmodule Alice.Music do
  alias Alice.Music.AuthStore
  alias Spotify.{Playlist,Track,Authentication}

  defmacro spotify_request(do: block) do
    quote do
      if authenticated? do
        refresh_credentials
        response = unquote(block)
        case response do
          {:ok, %{"error" => error}} -> handle_error(error)
          {:ok, response}            -> {:ok, response}
          unknown                    -> handle_error({:unknown, unknown})
        end
      else
        handle_error(:unauthenticated)
      end
    end
  end

  defp handle_error(%{"message" => message}), do: {:error, message}
  defp handle_error(%{}), do: {:error, "Unknown Error"}
  defp handle_error({:unknown, error}), do: {:error, "Unknown Error: #{inspect error}"}
  defp handle_error(:unauthenticated), do: {:error, "Unauthenticated: Please authenticate first."}

  def authenticated? do
    auth
    |> Authentication.authenticated?
    |> case do
      nil -> false
      _ -> true
    end
  end

  def authenticate(params) do
    auth = AuthStore.get_auth
    with {:ok, auth} <- Spotify.Authentication.authenticate(auth, params) do
      AuthStore.put_auth(auth)
      :ok
    end
  end

  def refresh_credentials do
    old_auth = auth
    with {:ok, %{access_token: token}} <- Spotify.Authentication.refresh(old_auth) do
      new_auth = Spotify.Credentials.new(token, old_auth.refresh_token)
      AuthStore.put_auth(new_auth)
      :ok
    end
  end

  def disconnect do
    AuthStore.clear_auth
  end

  def auth do
    AuthStore.get_auth
  end

  @doc """
  returns {:ok, track} or {:error, message}
  """
  def track(id) do
    spotify_request do
      Track.get_track(auth, id)
    end
  end

  @doc """
  returns :ok or {:error, message}
  """
  def add_track(track, to: playlist) do
    spotify_request do
      Spotify.Playlist.add_tracks(auth, user, playlist.id, uris: track.uri)
    end
  end

  @doc """
  returns {:ok, tracklist} or {:error, message}
  """
  def get_playlist_tracks(playlist) do
    spotify_request do
      Spotify.Playlist.get_playlist_tracks(auth, user, playlist.id)
    end
  end

  @doc """
  returns :ok or {:error, message}
  """
  def cleanup_playlist(playlist) do
    with {:ok, tracklist} <- get_playlist_tracks(playlist),
         uris <- dedup_and_trim_tracks(tracklist.items) do
      {status, _} = Spotify.Playlist.replace_tracks(auth, user, playlist.id, uris: uris)
      status
    end
  end

  defp dedup_and_trim_tracks(tracks) do
    tracks
    |> Stream.map(&(&1.track.uri))
    |> Enum.reverse
    |> Enum.uniq
    |> Enum.reverse
    |> Enum.take(-5)
    |> Enum.join(",")
  end

  def playlist(:no_playlist) do
    body = Poison.encode!(%{name: "Alice Music", public: true})
    {:ok, playlist} = Playlist.create_playlist(auth, user, body)
    playlist
  end
  def playlist(id) do
    {:ok, playlist} = Playlist.get_playlist(auth, user, id)
    playlist
  end

  defp user, do: Spotify.current_user
end
