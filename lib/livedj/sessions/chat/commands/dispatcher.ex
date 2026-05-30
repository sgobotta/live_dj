defmodule Livedj.Sessions.Chat.Commands.Dispatcher do
  @moduledoc """
  Routes parsed chat commands to the appropriate server.

  All paths go through `Parser.parse/1` first. Plain text and reactions go to
  `Sessions.chat_send_message/5`. Room-control commands (`/skip`, `/queue`)
  go to the relevant Sessions functions. `/name` updates the ChatServer's
  cached display names. `/msg` delivers to a remote room's ChatServer.
  """

  alias Livedj.Sessions
  alias Livedj.Sessions.{Chat.Commands.Parser, ChatSupervisor}

  @spec dispatch(binary(), binary(), binary(), binary()) :: :ok
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
        Sessions.next_track(room_id)

        Sessions.chat_send_message(
          room_id,
          user_id,
          display_name,
          :command_result,
          "Skipped to next track."
        )

      {:ok, {:queue, url}} ->
        case Sessions.add_media(room_id, url) do
          {:ok, {:added, media}} ->
            Sessions.chat_send_message(
              room_id,
              user_id,
              display_name,
              :command_result,
              "Queued: #{media.title}"
            )

          {:error, {_severity, reason}} ->
            Sessions.chat_send_message(
              room_id,
              user_id,
              display_name,
              :system,
              "Could not queue: #{reason}"
            )
        end

      {:ok, {:name, new_name}} ->
        Sessions.chat_update_display_name(room_id, user_id, new_name)

      {:ok, {:msg, target_room_id, content}} ->
        case ChatSupervisor.get_child(target_room_id) do
          nil ->
            Sessions.chat_send_message(
              room_id,
              user_id,
              display_name,
              :system,
              "Room not found: #{target_room_id}"
            )

          _child ->
            Sessions.chat_send_message(
              target_room_id,
              user_id,
              display_name,
              :text,
              content
            )
        end

      {:error, {:unknown_command, cmd}} ->
        Sessions.chat_send_message(
          room_id,
          user_id,
          display_name,
          :system,
          "Unknown command: /#{cmd}"
        )
    end
  end
end
