defmodule Livedj.Sessions do
  @moduledoc """
  The Sessions context.
  """

  import Ecto.Query, warn: false
  alias Livedj.Repo

  alias Livedj.Sessions.{Room, Supervisor}

  defdelegate child_spec(init_arg), to: Supervisor

  def pubsub_start do
    Redis.PubSub.start()
  end

  def pubsub_subscribe(pubsub, room_id, pid) do
    Redis.PubSub.susbcribe(pubsub, "room:" <> room_id, pid)
  end

  def current_track(id) do
    Redis.get(id)
  end

  def current_track(id, value) do
    Redis.set(id, value)
  end

  def queue_track(room_id, track) do
    key = track_queue_key(room_id)
    value = track.id
    Redis.zadd(key, 1, value)
  end

  defp track_queue_key(key) do
    "track_queue_#{key}"
  end

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    Repo.all(Room)
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id), do: Repo.get!(Room, id)

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{data: %Room{}}

  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end
end
