defmodule Livedj.Sessions.Chat.Message do
  @moduledoc false

  @type message_type :: :text | :system | :reaction | :command_result

  @type t :: %__MODULE__{
          id: binary(),
          room_id: binary(),
          user_id: binary(),
          display_name: binary(),
          type: message_type(),
          content: binary(),
          inserted_at: DateTime.t()
        }

  defstruct [
    :id,
    :room_id,
    :user_id,
    :display_name,
    :type,
    :content,
    :inserted_at
  ]

  @spec new(binary(), binary(), binary(), message_type(), binary()) :: t()
  def new(room_id, user_id, display_name, type, content) do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      room_id: room_id,
      user_id: user_id,
      display_name: display_name,
      type: type,
      content: content,
      inserted_at: DateTime.utc_now()
    }
  end
end
