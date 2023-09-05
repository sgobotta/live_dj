defmodule Livedj.Sessions do
  @moduledoc """
  The Sessions context.
  """

  import Ecto.Query, warn: false
  import LivedjWeb.Gettext

  alias Livedj.Media
  alias Livedj.Repo

  alias Livedj.Sessions.{
    Channels,
    Playlist,
    PlaylistServer,
    PlaylistSupervisor,
    Room,
    Supervisor
  }

  alias Livedj.Sessions.Exceptions.SessionRoomError

  require Logger

  # ----------------------------------------------------------------------------
  # Playlist server management
  #

  defdelegate child_spec(init_arg), to: Supervisor

  @doc """
  Joins the playlist server and subscribes to the playlist topic for a room.
  """
  @spec join_playlist(binary()) :: {:ok, :joined}
  def join_playlist(room_id) do
    :ok = Channels.subscribe_playlist_topic(room_id)

    case PlaylistSupervisor.get_child(room_id) do
      nil ->
        {:ok, pid} = PlaylistSupervisor.start_child(id: room_id)
        pid

      {pid, _state} when is_pid(pid) ->
        pid
    end
    |> PlaylistServer.join(on_joined: {&get_playlist/1, [room_id]})
  end

  @doc """
  Adds a media element to the playlist
  """
  @spec add_media(Ecto.UUID.t(), map()) :: PlaylistServer.add_response()
  def add_media(room_id, media_attrs) do
    case Media.create_video(media_attrs) do
      {:ok, %Media.Video{} = media} ->
        get_child_pid!(room_id)
        |> PlaylistServer.add(
          on_add: {&on_add/2, [room_id, media]},
          on_added: {&on_added/2, [room_id, media]}
        )

      {:error, %Ecto.Changeset{}} ->
        {:error, dgettext("errors", "Could not save track. Please try again.")}
    end
  end

  @spec on_add(Ecto.UUID.t(), any()) :: :ok | {:error, :element_exists}
  defp on_add(room_id, media) do
    case Playlist.add(room_id, media.external_id) do
      :ok ->
        :ok

      {:error, :element_exists} ->
        {:error,
         dgettext("errors", "The video is already added to the playlist")}
    end
  end

  @spec on_added(Ecto.UUID.t(), any()) :: :ok
  defp on_added(room_id, media),
    do: Channels.broadcast_playlist_track_added!(room_id, media)

  @doc """
  Removes a media element from the playlist
  """
  @spec remove_media(binary(), any()) :: PlaylistServer.remove_response()
  def remove_media(room_id, media) do
    get_child_pid!(room_id)
    |> PlaylistServer.remove(media)
  end

  @doc """
  Given a room id, a media identifier, a condition, a target element and some
  options, attempts to move the track referenced to a new index.

  ### Opts:

  - new_index: `integer()`
  - old_index: `integer()`

  """
  @spec move_media(
          Ecto.UUID.t(),
          String.t(),
          boolean(),
          String.t(),
          keyword()
        ) :: {:ok, :moved} | {:error, any()}
  def move_media(room_id, media_identifier, inserted_after?, target_id, _opts) do
    get_child_pid!(room_id)
    |> PlaylistServer.move(
      on_move:
        {&on_move/4, [room_id, media_identifier, inserted_after?, target_id]},
      on_moved: {&get_playlist/1, [room_id]}
    )
  end

  @spec on_move(Ecto.UUID.t(), String.t(), boolean(), String.t()) ::
          {:ok, :moved} | {:error, any()}
  defp on_move(room_id, media_identifier, inserted_after?, target_id) do
    case Playlist.move(room_id, media_identifier, inserted_after?, target_id) do
      {:ok, result} ->
        Logger.debug("#{__MODULE__} :: Moved result=#{inspect(result)}")
        {:ok, :moved}

      {:error, error} = e ->
        Logger.error(
          "#{__MODULE__}.move_media/5 :: Error room_id=#{inspect(room_id)} media_identifier=#{inspect(media_identifier)} inserted_after?=#{inspect(inserted_after?)} target_id=#{inspect(target_id)} error=#{inspect(error)}"
        )

        e
    end
  end

  @doc """
  Given a room id, returns a list of media.
  """
  @spec get_playlist(Ecto.UUID.t()) ::
          {:ok, list(map())} | {:error, any()}
  def get_playlist(room_id) do
    case Playlist.get(room_id) do
      {:ok, result} ->
        Logger.debug("#{__MODULE__} :: Get playlist result=#{inspect(result)}")

        # Refactor to Media.list/1
        list =
          Enum.map(result, fn media_external_id ->
            {:ok, media} = Media.get_by_external_id(media_external_id)

            media
          end)

        {:ok, list}

      {:error, error} = e ->
        Logger.error(
          "#{__MODULE__} :: Error on Redis.List.range error=#{inspect(error)}"
        )

        e
    end
  end

  @doc """
  Sends a locking request to the playlist server.
  """
  @spec lock_playlist_drag(binary()) :: PlaylistServer.lock_response()
  def lock_playlist_drag(room_id) do
    get_child_pid!(room_id)
    |> PlaylistServer.lock()
  end

  @doc """
  Sends an unlocking request to the playlist server.
  """
  @spec unlock_playlist_drag(binary(), pid()) ::
          PlaylistServer.unlock_response()
  def unlock_playlist_drag(room_id, from) do
    get_child_pid!(room_id)
    |> PlaylistServer.unlock(from)
  end

  defp get_child_pid!(room_id), do: PlaylistSupervisor.get_child_pid!(room_id)

  # ----------------------------------------------------------------------------
  # Media management
  #

  @doc """
  Given an external_id, fetches a video metadata through the Tubex api.
  """
  @spec fetch_media_metadata_by_id(binary()) ::
          {:error, :tubex_error} | {:ok, map()}
  def fetch_media_metadata_by_id(external_id) do
    case Tubex.Video.metadata(external_id) do
      {:error, error} ->
        Logger.error(
          "#{__MODULE__} :: There was an error fetching a video metadata err=#{inspect(error)}"
        )

        {:error, :tubex_error}

      metadata ->
        {:ok, metadata}
    end
  end

  @spec create_media(map()) :: {:ok, map()}
  def create_media(media, id \\ nil) do
    media = %{
      name: media["snippet"]["localized"]["title"],
      id: id || Ecto.UUID.generate(),
      external_id: media["id"],
      thumbnail_url: media["snippet"]["thumbnails"]["default"]["url"],
      thumbnail_width: media["snippet"]["thumbnails"]["default"]["width"],
      thumbnail_height: media["snippet"]["thumbnails"]["default"]["height"]
    }

    {:ok, media}
  end

  # ----------------------------------------------------------------------------
  # Redis management
  #

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
  def get_room!(id) do
    Repo.get!(Room, id)
  rescue
    Ecto.NoResultsError ->
      reraise SessionRoomError, [reason: :room_not_found], __STACKTRACE__
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
end
