defmodule LiveDj.Collections do
  @moduledoc """
  The Collections context.
  """

  import Ecto.Query, warn: false
  alias LiveDj.Repo

  alias LiveDj.Collections.Video

  @doc """
  Returns the list of videos.

  ## Examples

      iex> list_videos()
      [%Video{}, ...]

  """
  def list_videos do
    Repo.all(Video)
  end

  @doc """
  Gets a single video.

  Raises `Ecto.NoResultsError` if the Video does not exist.

  ## Examples

      iex> get_video!(123)
      %Video{}

      iex> get_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_video!(id), do: Repo.get!(Video, id)

  @doc """
  Creates a video.

  ## Examples

      iex> create_video(%{field: value})
      {:ok, %Video{}}

      iex> create_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_video(attrs \\ %{}) do
    %Video{}
    |> Video.changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc """
  Updates a video.

  ## Examples

      iex> update_video(video, %{field: new_value})
      {:ok, %Video{}}

      iex> update_video(video, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_video(%Video{} = video, attrs) do
    video
    |> Video.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a video.

  ## Examples

      iex> delete_video(video)
      {:ok, %Video{}}

      iex> delete_video(video)
      {:error, %Ecto.Changeset{}}

  """
  def delete_video(%Video{} = video) do
    Repo.delete(video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking video changes.

  ## Examples

      iex> change_video(video)
      %Ecto.Changeset{data: %Video{}}

  """
  def change_video(%Video{} = video, attrs \\ %{}) do
    Video.changeset(video, attrs)
  end

  alias LiveDj.Collections.UserVideo

  @doc """
  Returns the list of users_videos.

  ## Examples

      iex> list_users_videos()
      [%UserVideo{}, ...]

  """
  def list_users_videos do
    Repo.all(UserVideo)
  end

  @doc """
  Gets a single user_video.

  Raises `Ecto.NoResultsError` if the User video does not exist.

  ## Examples

      iex> get_user_video!(123)
      %UserVideo{}

      iex> get_user_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_video!(id), do: Repo.get!(UserVideo, id)

  @doc """
  Creates a user_video.

  ## Examples

      iex> create_user_video(%{field: value})
      {:ok, %UserVideo{}}

      iex> create_user_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_video(attrs \\ %{}) do
    %UserVideo{}
    |> UserVideo.changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc """
  Updates a user_video.

  ## Examples

      iex> update_user_video(user_video, %{field: new_value})
      {:ok, %UserVideo{}}

      iex> update_user_video(user_video, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_video(%UserVideo{} = user_video, attrs) do
    user_video
    |> UserVideo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_video.

  ## Examples

      iex> delete_user_video(user_video)
      {:ok, %UserVideo{}}

      iex> delete_user_video(user_video)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_video(%UserVideo{} = user_video) do
    Repo.delete(user_video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_video changes.

  ## Examples

      iex> change_user_video(user_video)
      %Ecto.Changeset{data: %UserVideo{}}

  """
  def change_user_video(%UserVideo{} = user_video, attrs \\ %{}) do
    UserVideo.changeset(user_video, attrs)
  end

  alias LiveDj.Collections.Playlist

  @doc """
  Returns the list of playlists.

  ## Examples

      iex> list_playlists()
      [%Playlist{}, ...]

  """
  def list_playlists do
    Repo.all(Playlist)
  end

  @doc """
  Gets a single playlist.

  Raises `Ecto.NoResultsError` if the Playlist does not exist.

  ## Examples

      iex> get_playlist!(123)
      %Playlist{}

      iex> get_playlist!(456)
      ** (Ecto.NoResultsError)

  """
  def get_playlist!(id), do: Repo.get!(Playlist, id)

  @doc """
  Creates a playlist.

  ## Examples

      iex> create_playlist(%{field: value})
      {:ok, %Playlist{}}

      iex> create_playlist(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_playlist(attrs \\ %{}) do
    %Playlist{}
    |> Playlist.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a playlist.

  ## Examples

      iex> update_playlist(playlist, %{field: new_value})
      {:ok, %Playlist{}}

      iex> update_playlist(playlist, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_playlist(%Playlist{} = playlist, attrs) do
    playlist
    |> Playlist.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a playlist.

  ## Examples

      iex> delete_playlist(playlist)
      {:ok, %Playlist{}}

      iex> delete_playlist(playlist)
      {:error, %Ecto.Changeset{}}

  """
  def delete_playlist(%Playlist{} = playlist) do
    Repo.delete(playlist)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking playlist changes.

  ## Examples

      iex> change_playlist(playlist)
      %Ecto.Changeset{data: %Playlist{}}

  """
  def change_playlist(%Playlist{} = playlist, attrs \\ %{}) do
    Playlist.changeset(playlist, attrs)
  end

  alias LiveDj.Collections.PlaylistVideo

  @doc """
  Returns the list of playlists_videos.

  ## Examples

      iex> list_playlists_videos()
      [%PlaylistVideo{}, ...]

  """
  def list_playlists_videos do
    Repo.all(PlaylistVideo)
  end

  @doc """
  Returns the list of playlists_videos that match the given id.

  ## Examples

      iex> list_playlists_videos_by_id(id)
      [%PlaylistVideo{}, ...]

  """
  def list_playlists_videos_by_id(id) do
    from(pv in PlaylistVideo, where: pv.playlist_id == ^id)
    |> Repo.all()
  end

  @doc """
  Gets a single playlist_video.

  Raises `Ecto.NoResultsError` if the Playlist video does not exist.

  ## Examples

      iex> get_playlist_video!(123)
      %PlaylistVideo{}

      iex> get_playlist_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_playlist_video!(id), do: Repo.get!(PlaylistVideo, id)

  @doc """
  Creates a playlist_video.

  ## Examples

      iex> create_playlist_video(%{field: value})
      {:ok, %PlaylistVideo{}}

      iex> create_playlist_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_playlist_video(attrs \\ %{}) do
    %PlaylistVideo{}
    |> PlaylistVideo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a playlist_video.

  ## Examples

      iex> update_playlist_video(playlist_video, %{field: new_value})
      {:ok, %PlaylistVideo{}}

      iex> update_playlist_video(playlist_video, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_playlist_video(%PlaylistVideo{} = playlist_video, attrs) do
    playlist_video
    |> PlaylistVideo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a playlist_video.

  ## Examples

      iex> delete_playlist_video(playlist_video)
      {:ok, %PlaylistVideo{}}

      iex> delete_playlist_video(playlist_video)
      {:error, %Ecto.Changeset{}}

  """
  def delete_playlist_video(%PlaylistVideo{} = playlist_video) do
    Repo.delete(playlist_video)
  end

  @doc """
  Given a video and a playlist, casts them into a PlaylistVideo struct

  ## Examples

      iex> cast_playlist_video(video, playlist)
      %PlaylistVideo{}

  """
  def cast_playlist_video(video, playlist_id) do
    get_by = fn video_id ->
      case Repo.get_by(Video, %{video_id: video_id}) do
        nil -> nil
        video -> video.id
      end
    end
    next_video = get_by.(video.next)
    previous_video = get_by.(video.previous)
    current_video = get_by.(video.video_id)
    %LiveDj.Collections.PlaylistVideo{
      position: video.position,
      playlist_id: playlist_id,
      video_id: current_video,
      next_video_id: next_video,
      previous_video_id: previous_video,
    }
  end

  @doc """
  Given a list of %PlaylistVideo{}, creates or updates each element.

  ## Examples

      iex> create_or_update_playlists_videos(playlists_videos)
      {:ok, [%PlaylistVideo{}]}

      iex> create_or_update_playlists_videos(playlists_videos)
      {:error}

  """
  def create_or_update_playlists_videos(playlists_videos) do
    for playlist_video <- playlists_videos do
      playlist_video = Repo.preload(
        playlist_video,
        [:playlist, :video, :previous_video, :next_video]
      )
      {:ok, playlist_video} = PlaylistVideo.changeset(playlist_video, %{})
      |>  Repo.insert_or_update(
        on_conflict: :replace_all,
        conflict_target: [:playlist_id, :position, :video_id]
      )
      playlist_video
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking playlist_video changes.

  ## Examples

      iex> change_playlist_video(playlist_video)
      %Ecto.Changeset{data: %PlaylistVideo{}}

  """
  def change_playlist_video(%PlaylistVideo{} = playlist_video, attrs \\ %{}) do
    PlaylistVideo.changeset(playlist_video, attrs)
  end

  @doc """
  Given a PlaylistVideo struct and a list of PlaylistVideo attributes, returns
  a preloaded struct
  """
  def preload_playlist_video(playlist_video, attrs \\ []) do
    Repo.preload(playlist_video, attrs)
  end
end
