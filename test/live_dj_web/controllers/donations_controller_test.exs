defmodule LiveDjWeb.DonationsControllerTest do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Accounts

  import LiveDj.AccountsFixtures
  import LiveDj.PaymentsFixtures
  import LiveDj.StatsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, LiveDjWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{
      badge: badge_fixture(reference_name: "payments-donate_once"),
      conn: conn,
      plan: plan_fixture(),
      user: user_fixture()
    }
  end

  describe "GET /donations" do
    test "visits the donations page as a visitor user", %{conn: conn} do
      conn = get(conn, Routes.donations_path(conn, :index))
      _response = html_response(conn, 200)

      assert assert get_flash(conn, :info) =~
                      "We're working on extra features and visuals. You can donate as a guest user but we recommend donating as a registered user to receive exclusive content."
    end

    test "visits the donations page as a registered user", %{conn: conn, user: user} do
      conn =
        log_in_user(conn, user)
        |> get(Routes.donations_path(conn, :index))

      _response = html_response(conn, 200)

      assert assert get_flash(conn, :info) =~
                      "Receive a donor badge by contributing to this project."
    end
  end

  describe "GET /donations/:donation_id" do
    test "receives a valid mercadopago donation as a visitor user", %{conn: conn, plan: plan} do
      attr = System.get_env("MERCADOPAGO_ATTR")

      conn =
        get(
          conn,
          Routes.donations_path(conn, :new, "mercadopago_completed", %{[attr] => plan.plan_id})
        )

      _response = html_response(conn, 302)
      assert "/donations/thanks" = redir_path = redirected_to(conn)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)
      assert response =~ "Thank you, Guest!"

      assert response =~
               "Your donation has been successfully processed. Contributions let us improve our efforts to make this site a better experience for you!"
    end

    test "receives a valid paypal donation as a visitor user", %{conn: conn} do
      plan =
        plan_fixture(%{
          plan_id: "234",
          gateway: "paypal",
          amount: 0.0,
          name: "standard",
          extra: [%{"input_value" => "asd123"}]
        })

      [attr, id, amount] = Poison.decode!(System.get_env("PAYPAL_ATTRS"))

      conn =
        get(
          conn,
          Routes.donations_path(
            conn,
            :new,
            "paypal_completed",
            %{[attr] => "{\"#{id}\": \"#{plan.plan_id}\"}", [amount] => "420.01"}
          )
        )

      _response = html_response(conn, 302)
      assert "/donations/thanks" = redir_path = redirected_to(conn)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)
      assert response =~ "Thank you, Guest!"

      assert response =~
               "Your donation has been successfully processed. Contributions let us improve our efforts to make this site a better experience for you!"
    end

    test "receives an invalid donation as a visitor user", %{conn: conn} do
      conn = get(conn, Routes.donations_path(conn, :new, "456"))
      _response = html_response(conn, 302)
      assert redirected_to(conn) == "/456"
    end

    test "receives a valid mercadopago donation as a registered user", %{
      badge: badge,
      conn: conn,
      plan: plan,
      user: user
    } do
      attr = System.get_env("MERCADOPAGO_ATTR")

      conn =
        log_in_user(conn, user)
        |> get(
          Routes.donations_path(conn, :new, "mercadopago_completed", %{[attr] => plan.plan_id})
        )

      %{badges: badges} = Accounts.get_user!(user.id) |> Accounts.preload_user([:badges])
      assert badge in badges
      _response = html_response(conn, 302)
      assert "/donations/thanks" = redir_path = redirected_to(conn)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)
      assert response =~ "Thank you, #{user.username}!"

      assert response =~
               "Your donation has been successfully processed. Contributions let us improve our efforts to make this site a better experience for you!"
    end

    test "receives a valid paypal donation as a registered user", %{
      badge: badge,
      conn: conn,
      user: user
    } do
      plan =
        plan_fixture(%{
          plan_id: "234",
          gateway: "paypal",
          amount: 0.0,
          name: "standard",
          extra: [%{"input_value" => "asd123"}]
        })

      [attr, id, amount] = Poison.decode!(System.get_env("PAYPAL_ATTRS"))

      conn =
        log_in_user(conn, user)
        |> get(
          Routes.donations_path(
            conn,
            :new,
            "paypal_completed",
            %{[attr] => "{\"#{id}\": \"#{plan.plan_id}\"}", [amount] => "420.01"}
          )
        )

      %{badges: badges} = Accounts.get_user!(user.id) |> Accounts.preload_user([:badges])
      assert badge in badges
      _response = html_response(conn, 302)
      assert "/donations/thanks" = redir_path = redirected_to(conn)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)
      assert response =~ "Thank you, #{user.username}!"

      assert response =~
               "Your donation has been successfully processed. Contributions let us improve our efforts to make this site a better experience for you!"
    end

    test "receives an invalid donation as a registered user", %{conn: conn, user: user} do
      conn =
        log_in_user(conn, user)
        |> get(Routes.donations_path(conn, :new, "456"))

      _response = html_response(conn, 302)
      assert redirected_to(conn) == "/456"
    end
  end
end
