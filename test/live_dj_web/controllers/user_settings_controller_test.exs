defmodule LiveDjWeb.UserSettingsControllerTest do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Accounts
  import LiveDj.AccountsFixtures
  import LiveDj.PaymentsFixtures

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders the main settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :index))
      response = html_response(conn, 200)
      assert response =~ "Account"
      assert response =~ "Payments"
      assert response =~ "Badges & Achievements"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :index))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "GET /users/settings/account" do
    test "renders account settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "Change Password"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end


  describe "GET /users/settings/payments" do
    test "renders payments page with empty content", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :show_payments))
      _response = html_response(conn, 200)
    end

    test "renders payments page with orders", %{conn: conn, user: user} do
      order_amount = "420.00"
      plan = plan_fixture()
      _order = order_fixture(%{amount: order_amount, plan_id: plan.id,
        user_id: user.id})
      conn = get(conn, Routes.user_settings_path(conn, :show_payments))
      _response = html_response(conn, 200)
      assert length(conn.assigns.orders) == 1
      assert Enum.any?(conn.assigns.orders, fn o ->
        o.amount == order_amount
      end)
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :show_payments))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "PUT /users/settings/update_password" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, Routes.user_settings_path(conn, :update_password), %{
          "current_password" => valid_user_password(),
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.user_settings_path(conn, :index)
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.user_settings_path(conn, :update_password), %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "1234",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "Change Password"
      assert response =~ "should be at least 6 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings/update_username" do
    @tag :capture_log
    test "updates the user username", %{conn: conn, user: user} do
      username = unique_user_username()
      conn =
        put(conn, Routes.user_settings_path(conn, :update_username), %{
          "current_password" => valid_user_password(),
          "user" => %{"username" => username}
        })

      assert redirected_to(conn) == Routes.user_settings_path(conn, :index)
      assert get_flash(conn, :info) =~ "Username updated successfully."
      assert Accounts.get_user_by_email(user.email).username == username
    end

    test "does not update username on short data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_username), %{
          "current_password" => "invalid",
          "user" => %{"username" => "me"}
        })

      response = html_response(conn, 200)
      assert response =~ "Change Password"
      assert response =~ "should be at least 3 character(s)"
      assert response =~ "is not valid"
    end

    test "does not update username on empty data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_username), %{
          "current_password" => "invalid",
          "user" => %{"username" => ""}
        })

      response = html_response(conn, 200)
      assert response =~ "Change Password"
      assert response =~ "can&#39;t be blank"
      assert response =~ "is not valid"
    end

    test "does not update username on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_username), %{
          "current_password" => "invalid",
          "user" => %{"username" => " "}
        })

      response = html_response(conn, 200)
      assert response =~ "Change Password"
      assert response =~ "can&#39;t be blank"
      assert response =~ "did not change"
      assert response =~ "is not valid"
    end

    test "does not update username on trailing spaces", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_username), %{
          "current_password" => "invalid",
          "user" => %{"username" => " sa"}
        })

      response = html_response(conn, 200)
      assert response =~ "Change Password"
      assert response =~ "should be at least 3 character(s)"
      assert response =~ "is not valid"
    end

    test "does not update username on consecutive spaces", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_username), %{
          "current_password" => "invalid",
          "user" => %{"username" => "a "}
        })

      response = html_response(conn, 200)
      assert response =~ "Change Password"
      assert response =~ "should be at least 3 character(s)"
      assert response =~ "is not valid"
    end

    test "does not update username on trailing and consecutive spaces", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_username), %{
          "current_password" => "invalid",
          "user" => %{"username" => "  a  "}
        })

      response = html_response(conn, 200)
      assert response =~ "Change Password"
      assert response =~ "should be at least 3 character(s)"
      assert response =~ "is not valid"
    end
  end

  describe "PUT /users/settings/update_email" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_email), %{
          "current_password" => valid_user_password(),
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == Routes.user_settings_path(conn, :index)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_email), %{
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "Change Password"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /users/settings/confirm_email/:token" do
    setup %{user: user} do
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :index)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :index)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :index)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "GET /users/settings/badges" do

    import LiveDj.StatsFixtures

    test "renders the badges and achievements page",
      %{conn: conn, user: user}
    do
      badge = badge_fixture()
      _user_badge = user_badge_fixture(%{badge_id: badge.id,
        user_id: user.id})
      conn = get(conn, Routes.user_settings_path(conn, :show_badges))
      response = html_response(conn, 200)
      assert response =~ "Badges & Achievements"
      user = Accounts.preload_user(conn.assigns.current_user, [:badges])
      assert length(user.badges) == 1
      assert Enum.member?(user.badges, badge)
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :show_badges))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
