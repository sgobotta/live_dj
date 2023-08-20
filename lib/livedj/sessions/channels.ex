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
  Subscribes to the playlist topic
  """
  @spec subscribe_playlist_topic(binary()) :: :ok | {:error, any()}
  def subscribe_playlist_topic(room_id),
    do: Phoenix.PubSub.subscribe(Livedj.PubSub, playlist_topic(room_id))

  @doc """
  Broadcasts a #{@dragging_locked} message to the given topic.
  """
  @spec notify_playlist_dragging_locked(pid(), binary()) :: :ok
  def notify_playlist_dragging_locked(from, room_id),
    do: broadcast_from!(from, playlist_topic(room_id), dragging_locked_event())

  @doc """
  Broadcasts a #{@dragging_unlocked} message to the given topic.
  """
  @spec notify_playlist_dragging_unlocked(pid(), binary()) :: :ok
  def notify_playlist_dragging_unlocked(from, room_id),
    do:
      broadcast_from!(from, playlist_topic(room_id), dragging_unlocked_event())

  @spec broadcast_from!(pid(), binary(), message()) :: :ok
  defp broadcast_from!(from, topic, message),
    do: Phoenix.PubSub.broadcast_from!(Livedj.PubSub, from, topic, message)
end
