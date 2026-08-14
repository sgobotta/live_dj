defmodule Livedj.Sessions.Chat.Commands.Dispatcher do
  @moduledoc """
  Routes parsed chat commands to the appropriate server.

  Returns `:ok` when the message was broadcast to all peers, or
  `{:local, message}` when the feedback is only for the sender (e.g. errors).
  """
  alias Livedj.{Media, Sessions}
  alias Livedj.Sessions.{Chat.Commands.Parser, Chat.Message, ChatSupervisor}

  import LivedjWeb.Gettext

  @type result ::
          :ok | {:local, Message.t()} | {:display_name_changed, binary()}

  @spec dispatch(binary(), binary(), binary(), binary()) :: result()
  def dispatch(room_id, user_id, display_name, raw_input) do
    case Parser.parse(raw_input) do
      {:ok, {:text, content}} ->
        Sessions.chat_send_message(
          room_id,
          user_id,
          display_name,
          :text,
          content
        )

      {:ok, {:me, content}} ->
        Sessions.chat_send_message(
          room_id,
          user_id,
          display_name,
          :reaction,
          content
        )

      {:ok, {:skip, _}} ->
        do_skip(room_id, user_id, display_name)

      {:ok, {:queue, url}} ->
        do_queue(room_id, user_id, display_name, url)

      {:ok, {:name, new_name}} ->
        do_update_name(room_id, user_id, display_name, new_name)

      {:ok, {:msg, target_room_id, content}} ->
        do_msg(room_id, user_id, display_name, target_room_id, content)

      {:error, {:unknown_command, cmd}} ->
        {:local,
         Message.new(
           room_id,
           user_id,
           display_name,
           :system,
           "Unknown command: /#{cmd}"
         )}
    end
  end

  defp do_update_name(room_id, user_id, display_name, new_name) do
    case String.trim(new_name) do
      "" ->
        {:local,
         Message.new(
           room_id,
           user_id,
           display_name,
           :system,
           gettext("Usage: /name <new name>")
         )}

      trimmed_name ->
        :ok = Sessions.chat_update_display_name(room_id, user_id, trimmed_name)
        {:display_name_changed, trimmed_name}
    end
  end

  defp do_skip(room_id, user_id, display_name) do
    Sessions.next_track(room_id, user_id, display_name)
  end

  defp do_queue(room_id, user_id, display_name, url) do
    case Sessions.add_media(
           room_id,
           Media.video_id_from_url(url),
           user_id,
           display_name
         ) do
      {:ok, {:added, _media}} ->
        :ok

      {:error, {_severity, reason}} ->
        {:local,
         Message.new(
           room_id,
           user_id,
           display_name,
           :system,
           gettext("Could not queue: %{reason}", reason: reason)
         )}
    end
  end

  defp do_msg(room_id, user_id, display_name, target_room_id, content) do
    case ChatSupervisor.get_child(target_room_id) do
      nil ->
        {:local,
         Message.new(
           room_id,
           user_id,
           display_name,
           :system,
           gettext("Room not found: %{target_room_id}",
             target_room_id: target_room_id
           )
         )}

      _child ->
        Sessions.chat_send_message(
          target_room_id,
          user_id,
          display_name,
          :text,
          content
        )
    end
  end
end
