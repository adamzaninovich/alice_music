defmodule Alice.Handlers.Music do
  use Alice.Router
  alias Alice.Music

  route ~r/\bspotify:track:(.*)\b/i, :add_track
  route ~r/open.spotify.com\/track\/(.*)\b/i, :add_track

  command ~r/(spotify|music) auth\z/i, :auth
  command ~r/(spotify|music) auth disconnect\z/i, :auth_disconnect
  command ~r/(spotify|music) auth status\z/i, :auth_status
  command ~r/(spotify|music) playlist\z/i, :playlist

  @doc """
  `<spotify track uri>` - adds the uri to the playlist
  """
  def add_track(conn) do
    if Music.authenticated? do
      with {conn = %Alice.Conn{}, playlist} <- find_or_create_playlist(conn),
           {:ok, track} <- conn |> Alice.Conn.last_capture |> Music.track,
           :ok <- Music.add_track(track, to: playlist),
           :ok <- Music.cleanup_playlist(playlist) do
        "#{music_emoji} Added track #{track.name} to the playlist #{playlist.name}."
      else
        {:error, message} -> message
      end
    else
      auth_status_response(false)
    end
    |> reply(conn)
  end

  @doc """
  `music auth` - returns a url to kick off the oauth process
  """
  def auth(conn) do
    Music.authenticated?
    |> auth_response
    |> reply(conn)
  end

  defp auth_response(true) do
    "#{music_emoji} I am already connected to Spotify! Use the command `@alice music auth disconnect` to disconnect."
  end
  defp auth_response(false) do
    "Click here :point_down: for #{music_emoji} :heart:\n#{Spotify.Authorization.url}"
  end

  @doc """
  `music auth disconnect` - disconnects from Spotify
  """
  def auth_disconnect(conn) do
    Music.disconnect
    "I have been disconnected from Spotify :broken_heart:"
    |> reply(conn)
  end

  @doc """
  `music auth status` - returns Spotify auth status
  """
  def auth_status(conn) do
    Music.authenticated?
    |> auth_status_response
    |> reply(conn)
  end

  defp auth_status_response(true) do
    "#{music_emoji} I am connected to Spotify and monitoring this channel for spotify URIs. #{music_emoji}"
  end
  defp auth_status_response(false) do
    ":-1: I am not connected Spotify. Please use the command `@alice music auth` to begin the process. :+1:"
  end

  @doc """
  `music playlist` - returns the playlist
  """
  def playlist(conn) do
    Music.authenticated?
    |> playlist_response(conn)
    |> fn({conn, resp}) -> reply(conn, resp) end.()
  end

  defp playlist_response(true, conn) do
    {conn, playlist} = find_or_create_playlist(conn)
    resp = "Here is the playlist --> *#{playlist.name}* #{playlist.uri}\nNow go follow it for mucho #{music_emoji}!"
    {conn, resp}
  end
  defp playlist_response(false, conn) do
    {conn, auth_status_response(false)}
  end

  defp music_emoji do
    ~w[:metal: :musical_note: :notes: :microphone: :headphones:
       :musical_score: :musical_keyboard: :guitar: :mega:
       :speaker: :sound: :loud_sound: :loudspeaker:]
     |> Enum.random
  end

  defp find_or_create_playlist(conn) do
    playlist = conn
               |> get_state(:music_playlist_id, :no_playlist)
               |> Music.playlist
    conn = put_state(conn, :music_playlist_id, playlist.id)
    {conn, playlist}
  end
end
