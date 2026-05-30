defmodule Livedj.Sessions.Channels do
  @moduledoc """
  Sessions channels and topic management.
  """

  require Logger

  @type message :: atom() | {atom(), any()} | {atom(), binary(), any()}

  # ----------------------------------------------------------------------------
  # Topics
  #
  @player_topic "player"
  @playlist_topic "playlist"
  @presence_topic "room_presence"
  @chat_topic "chat"

  # ----------------------------------------------------------------------------
  # Player event aliases
  #
  @player_joined :player_joined
  @player_state_changed :player_state_changed
  @player_play :player_play
  @player_pause :player_pause
  @player_load_media :player_load_media
  @track_ended :track_ended

  # ----------------------------------------------------------------------------
  # Playlist event aliases
  #

  @dragging_locked :dragging_locked
  @dragging_unlocked :dragging_unlocked
  @dragging_cancelled :dragging_cancelled
  @playlist_joined :playlist_joined
  @track_added :track_added
  @track_removed :track_removed
  @track_moved :track_moved

  # ----------------------------------------------------------------------------
  # Chat event aliases
  #

  @message_sent :message_sent
  @messages_updated :messages_updated

  # ----------------------------------------------------------------------------
  # Player topics
  #

  @doc """
  Returns the player topic
  """
  @spec player_topic() :: binary()
  def player_topic, do: @player_topic

  @doc """
  Returns the player topic for a room
  """
  @spec player_topic(binary()) :: binary()
  def player_topic(room_id), do: player_topic() <> ":" <> room_id

  # ----------------------------------------------------------------------------
  # Playlist topics
  #

  @doc """
  Returns the playlist topic
  """
  @spec playlist_topic() :: binary()
  def playlist_topic, do: @playlist_topic

  @doc """
  Returns the playlist topic for a room
  """
  @spec playlist_topic(binary()) :: binary()
  def playlist_topic(room_id), do: playlist_topic() <> ":" <> room_id

  # ----------------------------------------------------------------------------
  # Presence topics
  #

  @doc """
  Returns the presence topic
  """
  @spec presence_topic() :: binary()
  def presence_topic, do: @presence_topic

  @doc """
  Returns the presence topic for a room
  """
  @spec presence_topic(binary()) :: binary()
  def presence_topic(room_id), do: presence_topic() <> ":" <> room_id

  # ----------------------------------------------------------------------------
  # Player subscriptions
  #

  @doc """
  Subscribes to the playlist topic
  """
  @spec subscribe_playlist_topic(binary()) :: :ok | {:error, any()}
  def subscribe_playlist_topic(room_id), do: subscribe(playlist_topic(room_id))

  # ----------------------------------------------------------------------------
  # Playlist subscriptions
  #

  @doc """
  Subscribes to the player topic
  """
  @spec subscribe_player_topic(binary()) :: :ok | {:error, any()}
  def subscribe_player_topic(room_id), do: subscribe(player_topic(room_id))

  # ----------------------------------------------------------------------------
  # Presence subscriptions
  #

  @doc """
  Subscribes to the presence topic for a room
  """
  @spec subscribe_presence_topic(binary()) :: :ok | {:error, any()}
  def subscribe_presence_topic(room_id), do: subscribe(presence_topic(room_id))

  # ----------------------------------------------------------------------------
  # Chat topics
  #

  @doc """
  Returns the chat topic for a room.
  """
  @spec chat_topic(binary()) :: binary()
  def chat_topic(room_id), do: @chat_topic <> ":" <> room_id

  # ----------------------------------------------------------------------------
  # Chat subscriptions
  #

  @doc """
  Subscribes to the chat topic for a room.
  """
  @spec subscribe_chat_topic(binary()) :: :ok | {:error, any()}
  def subscribe_chat_topic(room_id), do: subscribe(chat_topic(room_id))

  # ----------------------------------------------------------------------------
  # Chat events
  #

  @doc """
  Returns the event name for message sent events.
  """
  @spec message_sent_event() :: :message_sent
  def message_sent_event, do: @message_sent

  @doc """
  Returns the event name for messages updated events.
  """
  @spec messages_updated_event() :: :messages_updated
  def messages_updated_event, do: @messages_updated

  # ----------------------------------------------------------------------------
  # Chat broadcasting
  #

  @doc """
  Broadcasts a message_sent message to the chat topic.
  """
  @spec broadcast_message_sent!(binary(), Livedj.Sessions.Chat.Message.t()) ::
          :ok
  def broadcast_message_sent!(room_id, message),
    do:
      broadcast!(chat_topic(room_id), {message_sent_event(), room_id, message})

  @doc """
  Broadcasts a messages_updated message to the chat topic.
  """
  @spec broadcast_messages_updated!(binary(), [Livedj.Sessions.Chat.Message.t()]) ::
          :ok
  def broadcast_messages_updated!(room_id, messages),
    do:
      broadcast!(
        chat_topic(room_id),
        {messages_updated_event(), room_id, messages}
      )

  # ----------------------------------------------------------------------------
  # Player events
  #

  @doc """
  Returns the message name for player joined events
  """
  @spec player_joined_event() :: :player_joined
  def player_joined_event, do: @player_joined

  @doc """
  Returns the message name for player state change events
  """
  @spec player_state_changed_event() :: :player_state_changed
  def player_state_changed_event, do: @player_state_changed

  @doc """
  Returns the message name for player play events
  """
  @spec player_play_event() :: :player_play
  def player_play_event, do: @player_play

  @doc """
  Returns the message name for player pause events
  """
  @spec player_pause_event() :: :player_pause
  def player_pause_event, do: @player_pause

  @doc """
  Returns the message name for player load media events
  """
  @spec player_load_media_event() :: :player_load_media
  def player_load_media_event, do: @player_load_media

  @doc """
  Returns the message name for track ended events
  """
  @spec track_ended_event() :: :track_ended
  def track_ended_event, do: @track_ended

  # ----------------------------------------------------------------------------
  # Playlist events
  #

  @doc """
  Returns the message name for dragging locked events
  """
  @spec dragging_locked_event() :: :dragging_locked
  def dragging_locked_event, do: @dragging_locked

  @doc """
  Returns the message name for dragging unlocked events
  """
  @spec dragging_unlocked_event() :: :dragging_unlocked
  def dragging_unlocked_event, do: @dragging_unlocked

  @doc """
  Returns the message name for dragging cancelled events
  """
  @spec dragging_cancelled_event() :: :dragging_cancelled
  def dragging_cancelled_event, do: @dragging_cancelled

  @doc """
  Returns the message name for track adding events
  """
  @spec track_added_event() :: :track_added
  def track_added_event, do: @track_added

  @doc """
  Returns the message name for track removed events
  """
  @spec track_removed_event() :: :track_removed
  def track_removed_event, do: @track_removed

  @doc """
  Returns the message name for track moving events
  """
  @spec track_moved_event() :: :track_moved
  def track_moved_event, do: @track_moved

  @doc """
  Returns the message name for playlist joined events
  """
  @spec playlist_joined_event() :: :playlist_joined
  def playlist_joined_event, do: @playlist_joined

  # ----------------------------------------------------------------------------
  # Player brodcasting
  #

  @doc """
  Broadcasts a #{@player_load_media} message to the player topic.
  """
  @spec broadcast_player_load_media!(binary(), Livedj.Sessions.Player.t()) ::
          :ok
  def broadcast_player_load_media!(room_id, player),
    do:
      broadcast!(
        player_topic(room_id),
        {player_load_media_event(), room_id, player}
      )

  @doc """
  Broadcasts a #{@player_play} message to the player topic.
  """
  @spec broadcast_player_state_change!(binary(), map()) :: :ok
  def broadcast_player_state_change!(
        room_id,
        %{player: %Livedj.Sessions.Player{}} = payload
      ),
      do:
        broadcast!(
          player_topic(room_id),
          {player_state_changed_event(), room_id, payload}
        )

  @doc """
  Broadcasts a #{@player_play} message to the player topic.
  """
  @spec broadcast_player_play!(binary(), Livedj.Sessions.Player.t()) :: :ok
  def broadcast_player_play!(room_id, %Livedj.Sessions.Player{} = player),
    do:
      broadcast!(player_topic(room_id), {player_play_event(), room_id, player})

  @doc """
  Broadcasts a #{@player_pause} message to the player topic.
  """
  @spec broadcast_player_pause!(binary(), Livedj.Sessions.Player.t()) :: :ok
  def broadcast_player_pause!(room_id, %Livedj.Sessions.Player{} = player),
    do:
      broadcast!(player_topic(room_id), {player_pause_event(), room_id, player})

  @doc """
  Broadcasts a #{@track_ended} message to the player topic.
  """
  @spec broadcast_player_track_ended!(binary()) :: :ok
  def broadcast_player_track_ended!(room_id),
    do: broadcast!(player_topic(room_id), {track_ended_event(), room_id})

  # ----------------------------------------------------------------------------
  # Playlist brodcasting
  #

  @doc """
  Broadcasts a #{@dragging_locked} message to the playlist topic.
  """
  @spec broadcast_playlist_dragging_locked!(pid(), binary()) :: :ok
  def broadcast_playlist_dragging_locked!(from, room_id),
    do: broadcast_from!(from, playlist_topic(room_id), dragging_locked_event())

  @doc """
  Broadcasts a #{@dragging_unlocked} message to the playlist topic.
  """
  @spec broadcast_playlist_dragging_unlocked!(pid(), binary()) :: :ok
  def broadcast_playlist_dragging_unlocked!(from, room_id),
    do:
      broadcast_from!(from, playlist_topic(room_id), dragging_unlocked_event())

  @doc """
  Broadcasts a #{@track_added} message to the playlist topic.
  """
  @spec broadcast_playlist_track_added!(binary(), any()) :: :ok
  def broadcast_playlist_track_added!(room_id, payload),
    do:
      broadcast!(
        playlist_topic(room_id),
        {track_added_event(), room_id, payload}
      )

  @doc """
  Broadcasts a #{@track_removed} message to the playlist topic.
  """
  @spec broadcast_playlist_track_removed!(binary(), any()) :: :ok
  def broadcast_playlist_track_removed!(room_id, payload),
    do:
      broadcast!(
        playlist_topic(room_id),
        {track_removed_event(), room_id, payload}
      )

  @doc """
  Broadcasts a #{@track_moved} message to the playlist topic.
  """
  @spec broadcast_playlist_track_moved!(binary(), any()) :: :ok
  def broadcast_playlist_track_moved!(room_id, payload),
    do:
      broadcast!(
        playlist_topic(room_id),
        {track_moved_event(), room_id, payload}
      )

  # ----------------------------------------------------------------------------
  # Player notifications
  #

  @doc """
  Notify a #{@player_joined} message.
  """
  @spec notify_player_joined(pid(), binary(), any()) :: message()
  def notify_player_joined(from, room_id, payload) do
    send(from, {player_joined_event(), room_id, payload})
  end

  # ----------------------------------------------------------------------------
  # Playlist notifications
  #

  @doc """
  Notify a #{@playlist_joined} message.
  """
  @spec notify_playlist_joined(pid(), binary(), any()) :: message()
  def notify_playlist_joined(from, room_id, payload),
    do: send(from, {playlist_joined_event(), room_id, payload})

  @doc """
  Notify a #{@dragging_cancelled} message.
  """
  @spec notify_playlist_dragging_cancelled(pid(), binary()) :: any()
  def notify_playlist_dragging_cancelled(from, room_id),
    do: send(from, {dragging_cancelled_event(), room_id})

  # ----------------------------------------------------------------------------
  # Private helpers
  #

  @spec subscribe(binary()) :: :ok | {:error, any()}
  defp subscribe(topic), do: Phoenix.PubSub.subscribe(Livedj.PubSub, topic)

  @spec broadcast_from!(pid(), binary(), message()) :: :ok
  defp broadcast_from!(from, topic, message),
    do: Phoenix.PubSub.broadcast_from!(Livedj.PubSub, from, topic, message)

  @spec broadcast!(binary(), message()) :: :ok
  defp broadcast!(topic, message),
    do: Phoenix.PubSub.broadcast!(Livedj.PubSub, topic, message)
end
