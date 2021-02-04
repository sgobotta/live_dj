defmodule LiveDjWeb.UserConfirmationController do
  use LiveDjWeb, :controller

  require Logger

  alias LiveDj.Accounts
  alias LiveDj.Stats

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &Routes.user_confirmation_url(conn, :confirm, &1)
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: "/")
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, user} ->
        badge_reference_name = "users-confirmed_via_link"
        case Stats.assoc_user_badge(user.id, badge_reference_name) do
          :ok -> Logger.info("Assigned badge #{badge_reference_name} to user #{user.id}")
          {:error, changeset} -> Logger.error("An error occurred while assignnig the #{badge_reference_name} badge. Details: #{inspect(changeset)}.")
        end
        conn
        |> put_flash(:info, "Account confirmed successfully.")
        |> redirect(to: "/")

      :error ->
        conn
        |> put_flash(:error, "Confirmation link is invalid or it has expired.")
        |> redirect(to: "/")
    end
  end
end
