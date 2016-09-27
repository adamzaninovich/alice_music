defmodule Alice.Music.AuthServer do
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :fetch_query_params
  plug :dispatch

  get "/alice/music/auth" do
    conn
    |> authenticate
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(200, html)
  end

  match(_) do
    send_resp(conn, 404, "not found")
  end

  defp authenticate(conn) do
    with :ok <- Alice.Music.authenticate(conn.params) do
      conn
    else
      error ->
        conn
        |> send_resp(500, "Spotify Auth Error: #{inspect error}")
        |> Plug.Conn.halt
    end
  end

  defp html do
    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>Alice Music</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <link href="https://d2d1dxiu3v1f2i.cloudfront.net/105311b/css/index.css" media="screen" rel="stylesheet">
      </head>
      <body>
        <div>
          <div class="container-fluid authorize">
            <div class="content">
              <div class="row">
                <div class="col-xs-12">
                  <div class="text-center">
                    <h1><strong>Success!</strong></h1>
                    <h2 class="client-name">You have connected <strong>Alice Music</strong> to your Spotify account.</h2>
                  </div>
                </div>
              </div>
              <div class="row">
                <div class="col-xs-12">
                  <a class="btn btn-sm btn-block btn-green" href="javascript:window.close();">Close this window</a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </body>
    </html>
    """
  end
end
