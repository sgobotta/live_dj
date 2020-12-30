defmodule LiveDjWeb.ErrorViewTest do
  use LiveDjWeb.ConnCase, async: true
  use Plug.Test

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  setup do
    conn =
      conn(:get, "/")
      |> Plug.Conn.put_private(:phoenix_endpoint, LiveDjWeb.Endpoint)

    {:ok, conn: conn}
  end

  test "renders 404.html", %{conn: conn} do
    assert render_to_string(LiveDjWeb.ErrorView, "404.html", conn: conn) =~ "Oops!"
    assert render_to_string(LiveDjWeb.ErrorView, "404.html", conn: conn) =~ "The page you were looking for doesn't exist or the link you clicked may be broken."
  end

  test "renders 500.html", %{conn: conn} do
    assert render_to_string(LiveDjWeb.ErrorView, "500.html", conn: conn) =~ "Oh no!"
    assert render_to_string(LiveDjWeb.ErrorView, "500.html", conn: conn) =~ "Our spaghetti code is not working properly. Time to paw through your logs and get down and dirty in your stack trace. We'll redirect you to the homepage in a few seconds."
  end
end
