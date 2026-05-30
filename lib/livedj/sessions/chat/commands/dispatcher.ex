defmodule Livedj.Sessions.Chat.Commands.Dispatcher do
  @moduledoc """
  Routes parsed chat commands to the appropriate server.

  Returns `:ok` when the message was broadcast to all peers, or
  `{:local, message}` when the feedback is only for the sender (e.g. errors).
  """

  alias Livedj.Sessions
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
            {:local,
             Message.new(
               room_id,
               user_id,
               display_name,
               :system,
               "Could not queue: #{reason}"
             )}
        end

      {:ok, {:name, new_name}} ->
        Sessions.chat_update_display_name(room_id, user_id, new_name)

      {:ok, {:msg, target_room_id, content}} ->
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
end
