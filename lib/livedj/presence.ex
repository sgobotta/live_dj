defmodule Livedj.Presence do
  @moduledoc """
  Tracks connected users per room.
  """
  use Phoenix.Presence,
    otp_app: :livedj,
    pubsub_server: Livedj.PubSub

  alias Livedj.Accounts.{Guest, User}
  alias Livedj.Sessions.Channels

  @doc """
  Registers the calling process as present in the given room.
  """
  @spec track_user(binary(), User.t() | Guest.t()) ::
          {:ok, binary()} | {:error, term()}
  def track_user(room_id, %User{} = user) do
    track(
      self(),
      Channels.presence_topic(room_id),
      user.id,
      %{username: user.username, email: user.email, avatar_url: nil}
    )
  end

  def track_user(room_id, %Guest{} = guest) do
    track(
      self(),
      Channels.presence_topic(room_id),
      guest.id,
      %{username: guest.username, email: nil, avatar_url: nil}
    )
  end

  @doc """
  Returns the list of user metadata maps for users present in the given room.
  """
  @spec list_users(binary()) :: [map()]
  def list_users(room_id) do
    room_id
    |> Channels.presence_topic()
    |> list()
    |> Enum.map(fn {_user_id, %{metas: [meta | _]}} -> meta end)
  end
end
