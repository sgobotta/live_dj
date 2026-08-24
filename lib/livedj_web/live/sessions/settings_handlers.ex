defmodule LivedjWeb.Sessions.SettingsHandlers do
  @moduledoc """
  Logic shared by the settings modal's General tab, which is rendered from
  both `RoomLive.Show` (in-room) and `RoomLive.Index` (rooms list). Each
  LiveView keeps its own `handle_event` clause so it can layer on its own
  side effects (e.g. Show also syncs the change into the room's live chat
  identity) but delegates the actual username update here.
  """

  alias Livedj.Accounts
  alias Livedj.Accounts.User

  import LivedjWeb.Gettext

  @doc """
  Updates the given user's username, returning a ready-to-flash error
  message on failure so callers don't need to know about changesets.
  """
  @spec update_username(User.t(), String.t()) ::
          {:ok, User.t()} | {:error, String.t()}
  def update_username(current_user, username) do
    case Accounts.update_user_username(current_user, %{"username" => username}) do
      {:ok, updated_user} ->
        {:ok, updated_user}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, username_error_message(changeset)}
    end
  end

  defp username_error_message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn error ->
      LivedjWeb.CoreComponents.translate_error(error)
    end)
    |> Map.get(:username, [])
    |> Enum.join(", ")
    |> case do
      "" -> gettext("Invalid username")
      message -> message
    end
  end
end
