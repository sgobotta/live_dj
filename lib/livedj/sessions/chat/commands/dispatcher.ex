defmodule Livedj.Sessions.Chat.Commands.Dispatcher do
  @moduledoc """
  Routes parsed chat commands to the appropriate server.

  Returns `:ok` when the message was broadcast to all peers, or
  `{:local, message}` when the feedback is only for the sender (e.g. errors).
  """

  alias Livedj.{Media, Sessions}
  alias Livedj.Sessions.{Chat.Commands.Parser, Chat.Message, ChatSupervisor}

  @type result :: :ok | {:local, Message.t()}

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
        Sessions.chat_update_display_name(room_id, user_id, new_name)

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

  defp do_skip(room_id, user_id, display_name) do
    Sessions.next_track(room_id)

    Sessions.chat_send_message(
      room_id,
      user_id,
      display_name,
      :command_result,
      "Skipped to next track."
    )
  end

  defp do_queue(room_id, user_id, display_name, url) do
    case Sessions.add_media(room_id, Media.video_id_from_url(url)) do
      {:ok, {:added, media}} ->
        {:local,
         Message.new(
           room_id,
           user_id,
           display_name,
           :command_result,
           "Queued: #{media.title}"
         )}

      {:error, {_severity, reason}} ->
        {:local,
         Message.new(
           room_id,
           user_id,
           display_name,
           :system,
           "Could not queue: #{reason}"
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
           "Room not found: #{target_room_id}"
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
