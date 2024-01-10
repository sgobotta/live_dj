defmodule LivedjWeb.PageControllerTest do
  use LivedjWeb.ConnCase

  import LivedjWeb.Gettext

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~
             gettext(
               "Share and listen to youtube videos in real time with others"
             )
  end
end
