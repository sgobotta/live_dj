defmodule Livedj.Sessions.Channels do
  @moduledoc """
  Sessions channels and topic management.
  """

  @type message :: atom()

  # ----------------------------------------------------------------------------
  # Topics
  #
  @playlist_topic "playlist"

  # ----------------------------------------------------------------------------
  # Events
  #
  @dragging_locked :dragging_locked
  @dragging_unlocked :dragging_unlocked
  @dragging_cancelled :dragging_cancelled
  @playlist_joined :playlist_joined

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
  Returns the message name for playlist joined events
  """
  @spec playlsit_joined_event() :: :playlist_joined
  def playlsit_joined_event, do: @playlist_joined

  @doc """
  Subscribes to the playlist topic
  """
  @spec subscribe_playlist_topic(binary()) :: :ok | {:error, any()}
  def subscribe_playlist_topic(room_id), do: subscribe(playlist_topic(room_id))

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
  Notify a #{@playlist_joined} message to the given topic.
  """
  @spec notify_playlsit_joined(pid(), binary(), any()) :: any()
  def notify_playlsit_joined(from, room_id, payload),
    do: send(from, {playlsit_joined_event(), room_id, payload})

  @doc """
  Notify a #{@dragging_cancelled} message to the given topic.
  """
  @spec notify_playlsit_dragging_cancelled(pid(), binary()) :: any()
  def notify_playlsit_dragging_cancelled(from, room_id),
    do: send(from, {dragging_cancelled_event(), room_id})

  @spec subscribe(binary()) :: :ok | {:error, any()}
  defp subscribe(topic), do: Phoenix.PubSub.subscribe(Livedj.PubSub, topic)

  @spec broadcast_from!(pid(), binary(), message()) :: :ok
  defp broadcast_from!(from, topic, message),
    do: Phoenix.PubSub.broadcast_from!(Livedj.PubSub, from, topic, message)
end
