defmodule Livedj.Media do
  @moduledoc """
  The Media context.
  """

  import Ecto.Query, warn: false
  alias Livedj.Repo

  alias Livedj.Media.{MediaCache, Video}

  require Logger

  @doc """
  Given a metadata reponse returns a success tuple when the result contains
  media metadata.
  """
  @spec from_tubex_metadata(map()) :: {:ok, map()} | {:error, :no_metadata}
  def from_tubex_metadata(media_metadata) do
    case media_metadata["items"] do
      [] ->
        {:error, :no_metadata}

      [media] ->
        {:ok,
         %{
           etag: media["etag"],
           external_id: media["id"],
           published_at: media["snippet"]["publishedAt"],
           thumbnail_url: media["snippet"]["thumbnails"]["default"]["url"],
           title: media["snippet"]["title"]
         }}
    end
  end

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
  def get_video!(id) do
    Repo.get!(Video, id)
  end

  @doc """
  Given an external id, fetches from the cache and fallbacks to the postgres
  db if no results were found.
  """
  @spec get_by_external_id(String.t()) ::
          {:ok, Video.t()} | {:error, Ecto.Changeset.t()}
  def get_by_external_id(external_id) do
    case MediaCache.get(external_id) do
      nil ->
        case Repo.get_by(Video, external_id: external_id) do
          nil ->
            {:error, :video_not_found}

          %Video{} = video ->
            MediaCache.insert(external_id, Video.from_struct(video))

            {:ok, video}
        end

      media ->
        {:ok, Video.from_hset(media)}
    end
  end

  @doc """
  Creates a video.

  ## Examples

      iex> create_video(%{field: value})
      {:ok, %Video{}}

      iex> create_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_video(map()) :: {:ok, Video.t()} | {:error, Ecto.Changeset.t()}
  def create_video(attrs \\ %{}) do
    %Video{}
    |> Video.changeset(attrs)
    |> Repo.insert()
    |> after_video_save()
  end

  @spec after_video_save({:ok, Video.t()} | {:error, Ecto.Changeset.t()}) ::
          {:ok, Video.t()} | {:error, Ecto.Changeset.t()}
  defp after_video_save({:ok, %Video{external_id: external_id} = video}) do
    case MediaCache.insert(external_id, Video.from_struct(video)) do
      {:ok, _video_hset} ->
        {:ok, video}

      {:error, :hset_error} ->
        Logger.error(
          "#{__MODULE__}.after_video_save/1 :: There was an error caching the video with id=#{video.id} external_id=#{external_id}"
        )

        {:ok, video}
    end
  end

  defp after_video_save(error), do: error

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
end
