defmodule LiveDj.Organizer do
  @moduledoc """
  The Organizer context.
  """

  import Ecto.Query, warn: false
  alias LiveDj.Repo
  alias LiveDj.Organizer.Room
  alias LiveDjWeb.Presence

  def list_present(slug) do
    Presence.list("room:" <> slug)
    # Check extra metadata needed from Presence
    |> Enum.map(fn {k, _} -> k end)
  end

  def list_present_with_metas(slug) do
    Presence.list("room:" <> slug)
    |> Enum.map(fn {uuid, %{metas: metas}} -> %{uuid: uuid, metas: metas} end)
  end

  def list_filtered_present(slug, uuid) do
    Presence.list("room:" <> slug)
    |> Enum.filter(fn {k, _} -> k !== uuid end)
    |> Enum.map(fn {k, _} -> k end)
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(LiveDj.PubSub, "rooms")
  end

  def subscribe(:request_initial_state, slug) do
    Phoenix.PubSub.subscribe(LiveDj.PubSub, "room:" <> slug <> ":request_initial_state")
  end

  def subscribe(:request_current_player, slug) do
    Phoenix.PubSub.subscribe(LiveDj.PubSub, "room:" <> slug <> ":request_current_player")
  end

  def subscribe(:play_next_of, slug, video_id) do
    Phoenix.PubSub.subscribe(LiveDj.PubSub, "room:" <> slug <> ":play_next_of:" <> video_id)
  end

  def unsubscribe(:request_initial_state, slug) do
    Phoenix.PubSub.unsubscribe(LiveDj.PubSub, "room:" <> slug <> ":request_initial_state")
  end

  def unsubscribe(:request_current_player, slug) do
    Phoenix.PubSub.unsubscribe(LiveDj.PubSub, "room:" <> slug <> ":request_current_player")
  end

  def unsubscribe(:play_next_of, slug, video_id) do
    Phoenix.PubSub.unsubscribe(LiveDj.PubSub, "room:" <> slug <> ":play_next_of:" <> video_id)
  end

  def is_my_presence(user, presence_payload) do
    Enum.any?(Map.to_list(presence_payload.joins), fn {x,_} -> x == user.uuid end) ||
    Enum.any?(Map.to_list(presence_payload.leaves), fn {x,_} -> x == user.uuid end)
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

  def get_room(slug) when is_binary(slug) do
    from(room in Room, where: room.slug == ^slug)
    |> Repo.one()
  end

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

  def viewers_quantity(room) do
    list_present(room.slug) |> length()
  end
end
