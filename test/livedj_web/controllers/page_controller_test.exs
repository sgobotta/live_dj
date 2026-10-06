defmodule LivedjWeb.PageControllerTest do
  use LivedjWeb.ConnCase

  import LivedjWeb.Gettext

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~
             gettext("Get started")
  end

  test "headline rotator CSS matches the phrase count" do
    assert length(LivedjWeb.PageHTML.headline_phrases()) == 10
  end
end
