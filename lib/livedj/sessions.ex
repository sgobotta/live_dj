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
    Chat,
    ChatServer,
    ChatSupervisor,
    PlaybackClock,
    PlaybackPosition,
    Player,
    PlayerServer,
    PlayerSupervisor,
    Playlist,
    PlaylistServer,
    PlaylistSupervisor,
    Room,
    Supervisor,
    VideoDuration
  }

  alias Livedj.Sessions.Exceptions.SessionRoomError

  require Logger

  @type player_state :: :playing | :paused

  defdelegate child_spec(init_arg), to: Supervisor

  # ----------------------------------------------------------------------------
  # Playlist server management
  #

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
  @spec add_media(Ecto.UUID.t(), String.t()) ::
          {:ok, {:added, Media.Video.t()}}
          | {:error, {:error | :warn, String.t()}}
  def add_media(room_id, media_identifier) do
    add_video = fn media ->
      get_playlist_child_pid!(room_id)
      |> PlaylistServer.add(
        on_add: {&on_add/2, [room_id, media]},
        on_added: {&on_added/2, [room_id, media]}
      )
    end

    with :ok <- Playlist.can_insert?(room_id, media_identifier),
         {:ok, %Media.Video{} = media} <-
           get_or_fetch_media_metadata_by_id(media_identifier),
         {:ok, :added} <- add_video.(media) do
      {:ok, {:added, media}}
    else
      {:error, :element_exists} ->
        {:error,
         {:warn,
          dgettext("errors", "The video is already added to the playlist")}}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error(
          "#{__MODULE__}.add_media/2 :: There was an error while creating the media, changeset=#{inspect(changeset)}"
        )

        {:error,
         {:error,
          dgettext(
            "errors",
            "Could not save video. Please try again later."
          )}}

      {:error, error} when error in [:tubex_error, :no_metadata] ->
        {:error,
         {:warn, dgettext("errors", "Could not fetch the video from youtube")}}
    end
  end

  @doc """
  Adds a media element to the playlist and announces it in the room's chat
  as `user_id`/`display_name`.
  """
  @spec add_media(Ecto.UUID.t(), String.t(), binary(), binary()) ::
          {:ok, {:added, Media.Video.t()}}
          | {:error, {:error | :warn, String.t()}}
  def add_media(room_id, media_identifier, user_id, display_name) do
    with {:ok, {:added, media}} = result <-
           add_media(room_id, media_identifier) do
      :ok =
        chat_send_message(
          room_id,
          user_id,
          display_name,
          :announcement,
          gettext("queued %{title}", title: media.title),
          media_title: media.title,
          media_channel: media.channel,
          media_thumbnail_url: media.thumbnail_url
        )

      result
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
  defp on_added(room_id, media) do
    {:ok, media_list} = Playlist.get(room_id)

    if length(media_list) == 1 do
      {:ok, player} = load_player_media(room_id, media, seek_to: 0)
      :ok = broadcast_player_load_media!(room_id, player)
    end

    :ok = Channels.broadcast_playlist_track_added!(room_id, media)
  end

  @doc """
  Removes a media element from the playlist
  """
  @spec remove_media(binary(), any()) :: PlaylistServer.remove_response()
  def remove_media(room_id, media_identifier) do
    get_playlist_child_pid!(room_id)
    |> PlaylistServer.remove(
      on_remove: {&on_remove/2, [room_id, media_identifier]},
      on_removed: {&on_removed/2, [room_id, media_identifier]}
    )
  end

  @spec on_remove(Ecto.UUID.t(), String.t()) :: :ok
  defp on_remove(room_id, media_identifier) do
    case Playlist.remove(room_id, media_identifier) do
      {:ok, :removed} ->
        :ok

      {:error, :noop} ->
        :ok
    end
  end

  @spec on_removed(Ecto.UUID.t(), String.t()) :: :ok
  defp on_removed(room_id, media_identifier) do
    {:ok, media_list} = Playlist.get(room_id)

    if media_list == [] do
      {:ok, %Player{} = player} = Player.clear_media(room_id)
      notify_playback_clock_track_loaded(room_id)
      :ok = Channels.broadcast_player_load_media!(room_id, player)
    end

    Channels.broadcast_playlist_track_removed!(room_id, media_identifier)
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
    get_playlist_child_pid!(room_id)
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
    get_playlist_child_pid!(room_id)
    |> PlaylistServer.lock()
  end

  @doc """
  Sends an unlocking request to the playlist server.
  """
  @spec unlock_playlist_drag(binary(), pid()) ::
          PlaylistServer.unlock_response()
  def unlock_playlist_drag(room_id, from) do
    get_playlist_child_pid!(room_id)
    |> PlaylistServer.unlock(from)
  end

  defp get_playlist_child_pid!(room_id),
    do: PlaylistSupervisor.get_child_pid!(room_id)

  # ----------------------------------------------------------------------------
  # Chat server management
  #

  @doc """
  Subscribes to the chat topic and returns the current message list for a room.
  """
  @spec join_chat(binary()) :: {:ok, [Chat.Message.t()]}
  def join_chat(room_id) do
    :ok = Channels.subscribe_chat_topic(room_id)

    pid =
      case ChatSupervisor.get_child(room_id) do
        nil ->
          case ChatSupervisor.start_child(id: room_id) do
            {:ok, pid} -> pid
            {:error, {:already_started, pid}} -> pid
          end

        {pid, _state} when is_pid(pid) ->
          pid
      end

    messages = ChatServer.get_messages(pid)
    {:ok, messages}
  end

  @doc """
  Sends a chat message for a user in a room.
  """
  @spec chat_send_message(
          binary(),
          binary(),
          binary(),
          Chat.Message.message_type(),
          binary(),
          keyword()
        ) ::
          :ok
  def chat_send_message(
        room_id,
        user_id,
        display_name,
        type,
        content,
        opts \\ []
      ) do
    ChatSupervisor.get_child_pid!(room_id)
    |> ChatServer.send_message(user_id, display_name, type, content, opts)
  end

  @doc """
  Updates the display name for all past messages of a user in a room.
  """
  @spec chat_update_display_name(binary(), binary(), binary()) :: :ok
  def chat_update_display_name(room_id, user_id, new_name) do
    ChatSupervisor.get_child_pid!(room_id)
    |> ChatServer.update_display_name(user_id, new_name)
  end

  # ----------------------------------------------------------------------------
  # Player server management
  #

  @doc """
  Joins the player server and subscribes to the player topic for a room.
  """
  @spec join_player(binary()) :: {:ok, :joined}
  def join_player(room_id) do
    :ok = Channels.subscribe_player_topic(room_id)

    case PlayerSupervisor.get_child(room_id) do
      nil ->
        {:ok, pid} = PlayerSupervisor.start_child(id: room_id)
        pid

      {pid, _state} when is_pid(pid) ->
        pid
    end
    |> PlayerServer.join(on_joined: {&get_player/1, [room_id]})
  end

  @doc """
  Called when a state change is performed on the player. Broadcasts the player
  struct.
  """
  @spec player_state_change(binary(), Player.t()) :: :ok
  def player_state_change(room_id, player) do
    :ok =
      room_id
      |> get_player_child_pid!()
      |> PlayerServer.state_change(
        on_state_change: {&on_state_change/2, [room_id, player]}
      )
  end

  @spec on_state_change(binary(), Player.t()) :: :ok
  defp on_state_change(room_id, player),
    do: Channels.broadcast_player_state_change!(room_id, %{player: player})

  @doc """
  Calls the player server to broadcast a play signal.
  """
  @spec play(binary(), keyword()) :: :ok
  def play(room_id, opts \\ []) do
    :ok =
      room_id
      |> get_player_child_pid!()
      |> PlayerServer.play(on_play: {&on_play/2, [room_id, opts]})
  end

  @spec on_play(binary(), keyword()) :: :ok
  defp on_play(room_id, _opts) do
    {:ok, %Player{} = player} =
      room_id
      |> ensure_playback_clock_pid!()
      |> PlaybackClock.play()

    :ok = Channels.broadcast_player_play!(room_id, player)
  end

  @doc """
  Calls the player server to broadcast a pause signal.
  """
  @spec pause(binary(), keyword()) :: :ok
  def pause(room_id, opts) do
    get_player_child_pid!(room_id)
    |> PlayerServer.pause(on_pause: {&on_pause/2, [room_id, opts]})
  end

  @spec on_pause(binary(), keyword()) :: :ok
  defp on_pause(room_id, opts) do
    {:ok, %Player{} = player} =
      room_id
      |> ensure_playback_clock_pid!()
      |> PlaybackClock.pause(opts)

    :ok = Channels.broadcast_player_pause!(room_id, player)
  end

  @doc """
  Reports that the YouTube player reached the end of the current track.

  Only the room controller (first joined LiveView, or next after disconnect)
  advances the playlist via `next_track/1`.
  """
  @spec report_track_ended(binary()) :: :ok
  def report_track_ended(room_id) do
    _response =
      room_id
      |> get_player_child_pid!()
      |> PlayerServer.report_track_ended(
        on_track_ended: {&on_track_ended/1, [room_id]}
      )

    :ok
  end

  @spec on_track_ended(binary()) :: :ok
  defp on_track_ended(room_id) do
    :ok = Channels.broadcast_player_track_ended!(room_id)

    case Player.get(room_id) do
      {:ok, %Player{duration: duration}}
      when is_integer(duration) and duration > 0 ->
        :ok

      _else ->
        next_track(room_id)
    end
  end

  @doc """
  Given a room id, returns a player.
  """
  @spec get_player(Ecto.UUID.t()) :: {:ok, Player.t()} | {:error, any()}
  def get_player(room_id) do
    case Player.get(room_id) do
      {:ok, player} ->
        synced = sync_player_position(room_id, player)

        Logger.debug("#{__MODULE__} :: Get player result=#{inspect(synced)}")

        {:ok, synced}

      {:error, error} = e ->
        Logger.error(
          "#{__MODULE__} :: Error on player fetch error=#{inspect(error)}"
        )

        e
    end
  end

  @doc """
  Given a room id, loads the previous track, broadcasts an update, and
  announces the change in the room's chat as a system message.
  """
  @spec previous_track(Ecto.UUID.t()) :: :ok
  def previous_track(room_id) do
    case advance_track(:previous, room_id) do
      {:ok, player} -> announce_now_playing(room_id, player)
      :error -> :ok
    end
  end

  @doc """
  Given a room id, loads the previous track, broadcasts an update, and
  announces the change in the room's chat as `user_id`/`display_name`.
  """
  @spec previous_track(Ecto.UUID.t(), binary(), binary()) :: :ok
  def previous_track(room_id, user_id, display_name) do
    case advance_track(:previous, room_id) do
      {:ok, player} ->
        announce_track_changed(room_id, user_id, display_name, player)

      :error ->
        :ok
    end
  end

  @doc """
  Given a room id, loads the next track, broadcasts an update, and
  announces the change in the room's chat as a system message.
  """
  @spec next_track(Ecto.UUID.t()) :: :ok
  def next_track(room_id) do
    case advance_track(:next, room_id) do
      {:ok, player} -> announce_now_playing(room_id, player)
      :error -> :ok
    end
  end

  @doc """
  Given a room id, loads the next track, broadcasts an update, and
  announces the change in the room's chat as `user_id`/`display_name`.
  """
  @spec next_track(Ecto.UUID.t(), binary(), binary()) :: :ok
  def next_track(room_id, user_id, display_name) do
    case advance_track(:next, room_id) do
      {:ok, player} ->
        announce_track_changed(room_id, user_id, display_name, player)

      :error ->
        :ok
    end
  end

  @spec advance_track(:previous | :next, Ecto.UUID.t()) ::
          {:ok, Player.t()} | :error
  defp advance_track(direction, room_id) do
    with {:ok, %Player{media_id: media_id}} <- get_player(room_id),
         {:ok, sibling_media_id} <-
           get_sibling_media_id(direction, room_id, media_id),
         {:ok, media} <- Media.get_by_external_id(sibling_media_id) do
      {:ok, player} =
        load_player_media(room_id, media, seek_to: 0, autoplay: true)

      :ok = broadcast_player_load_media!(room_id, player)
      {:ok, player}
    else
      _error -> :error
    end
  end

  defp get_sibling_media_id(:previous, room_id, media_id),
    do: Playlist.get_previous(room_id, media_id)

  defp get_sibling_media_id(:next, room_id, media_id),
    do: Playlist.get_next(room_id, media_id)

  @spec announce_track_changed(binary(), binary(), binary(), Player.t()) :: :ok
  defp announce_track_changed(room_id, user_id, display_name, %Player{
         title: title,
         channel: channel,
         media_thumbnail_url: media_thumbnail_url
       }) do
    chat_send_message(
      room_id,
      user_id,
      display_name,
      :announcement,
      gettext("changed the song to %{title}", title: title),
      media_title: title,
      media_channel: channel,
      media_thumbnail_url: media_thumbnail_url
    )
  end

  @spec announce_now_playing(binary(), Player.t()) :: :ok
  defp announce_now_playing(room_id, %Player{title: title}) do
    chat_send_message(
      room_id,
      "system",
      "System",
      :system,
      gettext("Now playing: %{title}", title: title)
    )
  end

  @doc """
  Given a room id and a media id loads the given track, broadcasts an
  update, and announces the change in the room's chat as
  `user_id`/`display_name`.
  """
  @spec play_track(Ecto.UUID.t(), String.t(), binary(), binary()) ::
          :ok | :error
  def play_track(room_id, selected_media_id, user_id, display_name) do
    with {:ok, media} <- Media.get_by_external_id(selected_media_id),
         {:ok, player} <-
           load_player_media(room_id, media, seek_to: 0, autoplay: true) do
      :ok = broadcast_player_load_media!(room_id, player)
      announce_track_changed(room_id, user_id, display_name, player)
    else
      _error ->
        :error
    end
  end

  defp get_player_child_pid!(room_id),
    do: PlayerSupervisor.get_child_pid!(room_id)

  @spec ensure_playback_clock_pid!(binary()) :: pid()
  defp ensure_playback_clock_pid!(room_id) do
    case PlayerSupervisor.start_playback_clock(room_id) do
      {:ok, pid} ->
        pid

      {:error, {:already_started, pid}} when is_pid(pid) ->
        pid
    end
  end

  @spec sync_player_position(binary(), Player.t()) :: Player.t()
  defp sync_player_position(_room_id, player) do
    PlaybackPosition.sync(player)
  end

  @spec load_player_media(binary(), Media.Video.t(), keyword()) ::
          {:ok, Player.t()} | {:error, any()}
  defp load_player_media(room_id, media, opts) do
    opts =
      case Keyword.get(opts, :duration) do
        duration when is_integer(duration) and duration > 0 ->
          opts

        _else ->
          case VideoDuration.fetch_seconds(media.external_id) do
            {:ok, seconds} -> Keyword.put(opts, :duration, seconds)
            {:error, _error} -> opts
          end
      end

    with {:ok, player} <- Player.load_media(room_id, media, opts) do
      notify_playback_clock_track_loaded(room_id)
      {:ok, PlaybackPosition.sync(player)}
    end
  end

  @spec broadcast_player_load_media!(binary(), Player.t()) :: :ok
  defp broadcast_player_load_media!(room_id, player),
    do: Channels.broadcast_player_load_media!(room_id, player)

  @spec notify_playback_clock_track_loaded(binary()) :: :ok
  defp notify_playback_clock_track_loaded(room_id) do
    case PlayerSupervisor.get_playback_clock(room_id) do
      {pid, _} -> PlaybackClock.track_loaded(pid)
      nil -> :ok
    end
  end

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

  @doc """
  Given a media indentifier, tries to get media data locally. If no records were
  found in Redis or Postgres, then a Tubex call is made to fetch they media's
  metadata. Finally, the media is persisted before returning a success value.
  """
  @spec get_or_fetch_media_metadata_by_id(String.t()) ::
          {:ok, Media.Video.t()}
          | {:error, :tubex_error}
          | {:error, :no_metadata}
          | {:error, :unexpected_error}
  def get_or_fetch_media_metadata_by_id(external_id) do
    case Media.get_by_external_id(external_id) do
      {:error, :video_not_found} ->
        with {:ok, metadata} when is_map(metadata) <-
               fetch_media_metadata_by_id(external_id),
             {:ok, media_attrs} when is_map(media_attrs) <-
               Livedj.Media.from_tubex_metadata(metadata) do
          Media.create_video(media_attrs)
        end

      {:ok, %Media.Video{external_id: ^external_id}} = response ->
        response
    end
  end

  @doc """
  Given a query, searches for videos through the Tubex api.
  """
  @spec search_by_query(String.t()) ::
          {:ok, [Media.Video.t()]} | {:error, :service_unavailable}
  def search_by_query(query) do
    opts = [maxResults: 20]

    case Tubex.Video.search_by_query(query, opts) do
      {:ok, search_result, _pag_opts} ->
        with medias <- Media.from_tubex_search(search_result),
             :ok <- create_videos(medias) do
          {:ok, medias}
        end

      {:error, %{"error" => %{"errors" => errors}}} ->
        for error <- errors do
          Logger.error(error["message"])
        end

        {:error, :service_unavailable}
    end
  end

  @spec create_videos([Media.Video.t()]) :: :ok
  defp create_videos(medias) do
    Enum.each(medias, fn media ->
      # TODO: handle constraints to the external_id to update those entities,
      # and cache the result.
      Media.create_video(media)
    end)
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

  # ----------------------------------------------------------------------------
  # Repo operations
  #

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

  @doc "Returns a randomly generated funny room name."
  def generate_room_name do
    patterns = [
      fn -> "#{Faker.Color.En.name()} #{Faker.Team.En.creature()}s" end,
      fn ->
        "The #{Faker.Team.En.creature()}s from #{Faker.StarWars.En.planet()}"
      end,
      fn -> "#{Faker.Pokemon.name()}'s #{Faker.Team.En.creature()}s" end,
      fn -> "#{Faker.Color.En.name()} #{Faker.Pokemon.name()} Lounge" end,
      fn ->
        "#{Faker.StarWars.En.planet()} #{Faker.Team.En.creature()}s Club"
      end
    ]

    Enum.random(patterns).()
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

  @doc "Returns true when the room has a password set."
  @spec room_protected?(Room.t()) :: boolean()
  def room_protected?(%Room{password_hash: hash}), do: not is_nil(hash)

  @doc """
  Verifies a plaintext password against a room's hash. Runs a dummy verify for
  unprotected rooms to avoid timing leaks, and always returns false for them.
  """
  @spec verify_room_password(Room.t(), binary()) :: boolean()
  def verify_room_password(%Room{password_hash: nil}, _password) do
    Bcrypt.no_user_verify()
    false
  end

  def verify_room_password(%Room{password_hash: hash}, password)
      when is_binary(password) do
    Bcrypt.verify_pass(password, hash)
  end

  def verify_room_password(%Room{}, _password), do: false

  @doc """
  Returns a short, stable fingerprint of the room's password hash, used to key
  session authorization so that changing the password re-locks other sessions.
  Returns nil for public rooms.
  """
  @spec authorization_fingerprint(Room.t()) :: binary() | nil
  def authorization_fingerprint(%Room{password_hash: nil}), do: nil

  def authorization_fingerprint(%Room{password_hash: hash}) do
    :crypto.hash(:sha256, hash)
    |> Base.encode16(case: :lower)
    |> binary_part(0, 16)
  end

  @doc """
  Subscribes the caller to a room's topic, used for room-wide events such as
  password changes.
  """
  @spec subscribe_room(binary()) :: :ok | {:error, any()}
  def subscribe_room(room_id), do: Channels.subscribe_room_topic(room_id)

  @doc "Sets, changes, or clears a room's password."
  @spec update_room_password(Room.t(), map()) ::
          {:ok, Room.t()} | {:error, Ecto.Changeset.t()}
  def update_room_password(%Room{} = room, attrs) do
    unless Map.has_key?(attrs, "password") or Map.has_key?(attrs, :password) do
      raise ArgumentError,
            "update_room_password/2 requires a :password (or \"password\") key; " <>
              "got: #{inspect(attrs)}"
    end

    case room |> Room.password_changeset(attrs) |> Repo.update() do
      {:ok, updated_room} = result ->
        :ok = Channels.broadcast_room_password_changed!(updated_room.id)
        result

      error ->
        error
    end
  end

  @doc "Renames a room from the room settings page."
  @spec update_room_name(Room.t(), map()) ::
          {:ok, Room.t()} | {:error, Ecto.Changeset.t()}
  def update_room_name(%Room{} = room, attrs) do
    unless Map.has_key?(attrs, "name") or Map.has_key?(attrs, :name) do
      raise ArgumentError,
            "update_room_name/2 requires a :name (or \"name\") key; " <>
              "got: #{inspect(attrs)}"
    end

    case room |> Room.name_changeset(attrs) |> Repo.update() do
      {:ok, updated_room} = result ->
        :ok = Channels.broadcast_room_name_changed!(updated_room.id)
        result

      error ->
        error
    end
  end
end
