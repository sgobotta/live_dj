defmodule LivedjWeb.UserSettingsLive do
  use LivedjWeb, :live_view

  alias Livedj.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <.simple_form
      for={@settings_form}
      id="settings_form"
      action={~p"/users/log_in?_action=password_updated"}
      method="post"
      phx-submit="update_settings"
      phx-trigger-action={@trigger_submit}
    >
      <%!-- Supplies user[email] for the re-login POST after a password change --%>
      <input type="hidden" name="user[email]" value={@current_email} />
      <.input field={@settings_form[:username]} type="text" label="Username" />
      <.input
        field={@settings_form[:new_email]}
        type="email"
        label="Email"
        required
      />
      <.input
        field={@settings_form[:password]}
        type="password"
        label="New password"
      />
      <.input
        field={@settings_form[:password_confirmation]}
        type="password"
        label="Confirm new password"
      />
      <.input
        field={@settings_form[:current_password]}
        name="current_password"
        id="current_password"
        type="password"
        label="Current password"
        value={@current_password}
      />
      <:actions>
        <.button phx-disable-with="Saving...">Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(
            socket,
            :error,
            "Email change link is invalid or it has expired."
          )
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:trigger_submit, false)
      |> assign(:settings_form, settings_form(user))

    {:ok, socket}
  end

  def handle_event(
        "update_settings",
        %{"current_password" => current_password, "user" => user_params},
        socket
      ) do
    user = socket.assigns.current_user

    {socket, trigger_submit} =
      {socket, false}
      |> apply_username_change(user, user_params)
      |> apply_email_change(user, user_params, current_password)
      |> apply_password_change(user, user_params, current_password)

    {:noreply,
     socket
     |> assign(:current_password, current_password)
     |> assign(:trigger_submit, trigger_submit)}
  end

  defp apply_username_change({socket, trigger}, user, %{"username" => username})
       when username != "" do
    case Accounts.update_user_username(user, %{"username" => username}) do
      {:ok, updated_user} ->
        {socket
         |> assign(:current_user, updated_user)
         |> assign(:settings_form, settings_form(updated_user))
         |> put_flash(:info, "Username updated."), trigger}

      {:error, _} ->
        {put_flash(socket, :error, "Could not update username."), trigger}
    end
  end

  defp apply_username_change(acc, _user, _params), do: acc

  defp apply_email_change(
         {socket, trigger},
         user,
         %{"new_email" => new_email},
         current_password
       )
       when new_email != "" do
    if new_email != user.email do
      case Accounts.apply_user_email(user, current_password, %{
             "email" => new_email
           }) do
        {:ok, applied_user} ->
          Accounts.deliver_user_update_email_instructions(
            applied_user,
            user.email,
            &url(~p"/users/settings/confirm_email/#{&1}")
          )

          {put_flash(socket, :info, "Confirmation sent to #{new_email}."),
           trigger}

        {:error, _} ->
          {put_flash(
             socket,
             :error,
             "Could not update email. Check your current password."
           ), trigger}
      end
    else
      {socket, trigger}
    end
  end

  defp apply_email_change(acc, _user, _params, _password), do: acc

  defp apply_password_change(
         {socket, _trigger},
         user,
         %{"password" => password} = user_params,
         current_password
       )
       when password != "" do
    case Accounts.update_user_password(user, current_password, user_params) do
      {:ok, _user} ->
        {socket, true}

      {:error, _} ->
        {put_flash(
           socket,
           :error,
           "Could not update password. Check your current password."
         ), false}
    end
  end

  defp apply_password_change(acc, _user, _params, _password), do: acc

  defp settings_form(user) do
    to_form(
      %{
        "username" => user.username,
        "new_email" => user.email,
        "password" => "",
        "password_confirmation" => "",
        "current_password" => ""
      },
      as: :user
    )
  end
end
