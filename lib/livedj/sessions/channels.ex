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

  # ----------------------------------------------------------------------------
  # Player event aliases
  #
  @player_joined :player_joined
  @player_play :player_play
  @player_pause :player_pause
  @player_load_media :player_load_media

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
  # Player events
  #

  @doc """
  Returns the message name for player joined events
  """
  @spec player_joined_event() :: :player_joined
  def player_joined_event, do: @player_joined

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
  @spec playlsit_joined_event() :: :playlist_joined
  def playlsit_joined_event, do: @playlist_joined

  # ----------------------------------------------------------------------------
  # Player brodcasting
  #

  @spec broadcast_player_load_media!(binary(), Livedj.Sessions.Player.t()) ::
          :ok
  def broadcast_player_load_media!(room_id, player),
    do:
      broadcast!(
        player_topic(room_id),
        {player_load_media_event(), room_id, player}
      )

  @doc """
  Broadcasts a #{@player_play} message to the given topic.
  """
  @spec broadcast_player_play!(binary()) :: :ok
  def broadcast_player_play!(room_id),
    do: broadcast!(player_topic(room_id), player_play_event())

  @doc """
  Broadcasts a #{@player_pause} message to the given topic.
  """
  @spec broadcast_player_pause!(binary()) :: :ok
  def broadcast_player_pause!(room_id),
    do: broadcast!(player_topic(room_id), player_pause_event())

  # ----------------------------------------------------------------------------
  # Playlist brodcasting
  #

  @doc """
  Broadcasts a #{@dragging_locked} message to the given topic.
  """
  @spec broadcast_playlist_dragging_locked!(pid(), binary()) :: :ok
  def broadcast_playlist_dragging_locked!(from, room_id),
    do: broadcast_from!(from, playlist_topic(room_id), dragging_locked_event())

  @doc """
  Broadcasts a #{@dragging_unlocked} message to the given topic.
  """
  @spec broadcast_playlist_dragging_unlocked!(pid(), binary()) :: :ok
  def broadcast_playlist_dragging_unlocked!(from, room_id),
    do:
      broadcast_from!(from, playlist_topic(room_id), dragging_unlocked_event())

  @doc """
  Broadcasts a #{@track_added} message to the given topic.
  """
  @spec broadcast_playlist_track_added!(binary(), any()) :: :ok
  def broadcast_playlist_track_added!(room_id, payload),
    do:
      broadcast!(
        playlist_topic(room_id),
        {track_added_event(), room_id, payload}
      )

  @doc """
  Broadcasts a #{@track_removed} message to the given topic.
  """
  @spec broadcast_playlist_track_removed!(binary(), any()) :: :ok
  def broadcast_playlist_track_removed!(room_id, payload),
    do:
      broadcast!(
        playlist_topic(room_id),
        {track_removed_event(), room_id, payload}
      )

  @doc """
  Broadcasts a #{@track_moved} message to the given topic.
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
  Notify a #{@player_joined} message to the given topic.
  """
  @spec notify_player_joined(pid(), binary(), any()) :: message()
  def notify_player_joined(from, room_id, payload) do
    send(from, {player_joined_event(), room_id, payload})
  end

  # ----------------------------------------------------------------------------
  # Playlist notifications
  #

  @doc """
  Notify a #{@playlist_joined} message to the given topic.
  """
  @spec notify_playlsit_joined(pid(), binary(), any()) :: message()
  def notify_playlsit_joined(from, room_id, payload),
    do: send(from, {playlsit_joined_event(), room_id, payload})

  @doc """
  Notify a #{@dragging_cancelled} message to the given topic.
  """
  @spec notify_playlsit_dragging_cancelled(pid(), binary()) :: any()
  def notify_playlsit_dragging_cancelled(from, room_id),
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
