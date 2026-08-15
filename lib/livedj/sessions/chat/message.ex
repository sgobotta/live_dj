defmodule Livedj.Sessions.Chat.Message do
  @moduledoc false

  @type message_type ::
          :text | :system | :reaction | :command_result | :announcement

  @type t :: %__MODULE__{
          id: binary(),
          room_id: binary(),
          user_id: binary(),
          display_name: binary(),
          type: message_type(),
          content: binary(),
          media_title: binary() | nil,
          media_channel: binary() | nil,
          media_thumbnail_url: binary() | nil,
          inserted_at: DateTime.t()
        }

  defstruct [
    :id,
    :room_id,
    :user_id,
    :display_name,
    :type,
    :content,
    :media_title,
    :media_channel,
    :media_thumbnail_url,
    :inserted_at
  ]

  @spec new(
          binary(),
          binary(),
          binary(),
          message_type(),
          binary(),
          keyword()
        ) :: t()
  def new(room_id, user_id, display_name, type, content, opts \\ []) do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      room_id: room_id,
      user_id: user_id,
      display_name: display_name,
      type: type,
      content: content,
      media_title: Keyword.get(opts, :media_title),
      media_channel: Keyword.get(opts, :media_channel),
      media_thumbnail_url: Keyword.get(opts, :media_thumbnail_url),
      inserted_at: DateTime.utc_now()
    }
  end
end
