defmodule LiveDjWeb.UserSettingsController do
  use LiveDjWeb, :controller

  alias LiveDj.Accounts
  alias LiveDjWeb.UserAuth

  plug :assign_initial_changesets

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update_username(conn, %{"current_password" => password, "user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.apply_user_username(user, password, user_params) do
      {:ok, _user} ->
        case Accounts.update_user_username(user, password, user_params) do
          {:ok, _user} ->
            conn
            |> put_flash(:info, "Username updated successfully.")
            |> put_session(:user_return_to, Routes.user_settings_path(conn, :index))
            |> redirect(to: Routes.user_settings_path(conn, :index))

          {:error, changeset} ->
            render(conn, "edit.html", username_changeset: changeset)
        end
      {:error, changeset} ->
        render(conn, "edit.html", username_changeset: changeset)
    end
  end

  def update_email(conn, %{"current_password" => password, "user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &Routes.user_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.user_settings_path(conn, :index))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.user_settings_path(conn, :index))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.user_settings_path(conn, :index))
    end
  end

  def update_password(conn, %{"current_password" => password, "user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :index))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  defp assign_initial_changesets(conn, _opts) do
    user = case conn.assigns.visitor do
      true -> nil
      false -> conn.assigns.current_user
    end
    conn
    |> assign(:username_changeset, Accounts.change_user_username(user))
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
