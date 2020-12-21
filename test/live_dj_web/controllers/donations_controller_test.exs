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

    %{user: user_fixture(), conn: conn, plan: plan_fixture()}
  end

  describe "GET /donations/:donation_id" do
    test "receives a valid donation as a visitor user", %{conn: conn, plan: plan} do
      conn = get(conn, Routes.donations_path(conn, :new, plan.plan_id))
      response = html_response(conn, 302)
      assert "/donations/thanks" = redir_path = redirected_to(conn)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)
      assert response =~ "Thank you, Guest!"
      assert response =~ "Your donation has been successfully processed. Contributions let us improve our efforts to make this site a better experience for you!"
    end

    test "receives an invalid donation as a visitor user", %{conn: conn, user: user} do
      conn = get(conn, Routes.donations_path(conn, :new, "456"))
      response = html_response(conn, 302)
      assert redirected_to(conn) == "/"
    end

    test "receives a valid donation as a registered user", %{conn: conn, plan: plan, user: user} do
      conn = log_in_user(conn, user)
        |> get(Routes.donations_path(conn, :new, plan.plan_id))
      response = html_response(conn, 302)
      assert "/donations/thanks" = redir_path = redirected_to(conn)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)
      assert response =~ "Thank you, #{user.username}!"
      assert response =~ "Your donation has been successfully processed. Contributions let us improve our efforts to make this site a better experience for you!"
    end

    test "receives an invalid donation as a registered user", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
        |> get(Routes.donations_path(conn, :new, "456"))
      response = html_response(conn, 302)
      assert redirected_to(conn) == "/"
    end

  end
end
