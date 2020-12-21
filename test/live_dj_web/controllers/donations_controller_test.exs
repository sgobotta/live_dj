defmodule LiveDjWeb.DonationsControllerTest do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Accounts
  alias LiveDjWeb.UserAuth
  import LiveDj.AccountsFixtures
  import LiveDj.PaymentsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, LiveDjWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    plan_fixture()
    %{user: user_fixture(), conn: conn}
  end

  describe "GET /donations/:donation_id" do
    test "receives a valid donation as a visitor user", %{conn: conn, user: user} do
      conn = get(conn, Routes.donations_path(conn, :new, "123"))
      response = html_response(conn, 302)
      assert redirected_to(conn) == "/donations/thanks"
    end

    test "receives an invalid donation as a visitor user", %{conn: conn, user: user} do
      conn = get(conn, Routes.donations_path(conn, :new, "456"))
      response = html_response(conn, 302)
      assert redirected_to(conn) == "/"
    end

    test "receives a valid donation as a registered user", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
        |> get(Routes.donations_path(conn, :new, "123"))
      response = html_response(conn, 302)
      assert redirected_to(conn) == "/donations/thanks"
    end

    test "receives an invalid donation as a registered user", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
        |> get(Routes.donations_path(conn, :new, "456"))
      response = html_response(conn, 302)
      assert redirected_to(conn) == "/"
    end

  end
end
