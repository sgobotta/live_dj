defmodule LiveDjWeb.DonationsControllerTest do
  use LiveDjWeb.ConnCase, async: true

  import LiveDj.AccountsFixtures
  import LiveDj.PaymentsFixtures

  setup %{conn: conn} do
    mercadopago_attr = System.get_env("MERCADOPAGO_ATTR")
    paypal_attrs = System.get_env("PAYPAL_ATTRS")
    IO.inspect("MERCADOPAGO ATTR: #{mercadopago_attr}")
    IO.inspect("PAYPAL ATTRS: #{paypal_attrs}")
    conn =
      conn
      |> Map.replace!(:secret_key_base, LiveDjWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: user_fixture(), conn: conn, plan: plan_fixture()}
  end

  describe "GET /donations" do
    test "visits the donations page as a visitor user", %{conn: conn} do
      conn = get(conn, Routes.donations_path(conn, :index))
      _response = html_response(conn, 200)
      assert assert get_flash(conn, :info) =~ "We're working on extra features and visuals. You can donate as a guest user but we recommend donating as a registered user to receive exclusive content."
    end

    test "visits the donations page as a registered user", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
        |> get(Routes.donations_path(conn, :index))
      _response = html_response(conn, 200)
      assert assert get_flash(conn, :info) =~ "Receive a donor badge by contributing to this project."
    end
  end

  describe "GET /donations/:donation_id" do
    test "receives a valid mercadopago donation as a visitor user", %{conn: conn, plan: plan} do
      attr = System.get_env("MERCADOPAGO_ATTR")
      conn = get(conn, Routes.donations_path(conn, :new, "mercadopago_completed", %{[attr] => plan.plan_id}))
      _response = html_response(conn, 302)
      assert "/donations/thanks" = redir_path = redirected_to(conn)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)
      assert response =~ "Thank you, Guest!"
      assert response =~ "Your donation has been successfully processed. Contributions let us improve our efforts to make this site a better experience for you!"
    end

    test "receives a valid paypal donation as a visitor user", %{conn: conn} do
      plan = plan_fixture(%{plan_id: "234", gateway: "paypal", amount: 0.0, name: "standard", extra: [%{"input_value" => "asd123"}]})
      [fst, snd] = Poison.decode!(System.get_env("PAYPAL_ATTRS"))
      conn = get(conn, Routes.donations_path(conn, :new, "paypal_completed", %{[fst] => "{\"#{snd}\": \"#{plan.plan_id}\"}"}))
      _response = html_response(conn, 302)
      assert "/donations/thanks" = redir_path = redirected_to(conn)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)
      assert response =~ "Thank you, Guest!"
      assert response =~ "Your donation has been successfully processed. Contributions let us improve our efforts to make this site a better experience for you!"
    end

    test "receives an invalid donation as a visitor user", %{conn: conn} do
      conn = get(conn, Routes.donations_path(conn, :new, "456"))
      _response = html_response(conn, 302)
      assert redirected_to(conn) == "/456"
    end

    test "receives a valid mercadopago donation as a registered user", %{conn: conn, user: user, plan: plan} do
      attr = System.get_env("MERCADOPAGO_ATTR")
      conn = log_in_user(conn, user)
        |> get(Routes.donations_path(conn, :new, "mercadopago_completed", %{[attr] => plan.plan_id}))
      _response = html_response(conn, 302)
      assert "/donations/thanks" = redir_path = redirected_to(conn)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)
      assert response =~ "Thank you, #{user.username}!"
      assert response =~ "Your donation has been successfully processed. Contributions let us improve our efforts to make this site a better experience for you!"
    end

    test "receives a valid paypal donation as a registered user", %{conn: conn, user: user} do
      plan = plan_fixture(%{plan_id: "234", gateway: "paypal", amount: 0.0, name: "standard", extra: [%{"input_value" => "asd123"}]})
      [fst, snd] = Poison.decode!(System.get_env("PAYPAL_ATTRS"))
      conn = log_in_user(conn, user)
        |> get(Routes.donations_path(conn, :new, "paypal_completed", %{[fst] => "{\"#{snd}\": \"#{plan.plan_id}\"}"}))
      _response = html_response(conn, 302)
      assert "/donations/thanks" = redir_path = redirected_to(conn)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)
      assert response =~ "Thank you, #{user.username}!"
      assert response =~ "Your donation has been successfully processed. Contributions let us improve our efforts to make this site a better experience for you!"
    end

    test "receives an invalid donation as a registered user", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
        |> get(Routes.donations_path(conn, :new, "456"))
      _response = html_response(conn, 302)
      assert redirected_to(conn) == "/456"
    end

  end
end
