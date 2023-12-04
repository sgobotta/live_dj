defmodule Livedj.Sessions.Playlist do
  @moduledoc false

  @key_prefix "playlist"

  @doc """
  Given a room id and a media indentifier (generally a youtube id), adds the
  value to the room playlist.
  """
  @spec add(Ecto.UUID.t(), String.t()) ::
          :ok | {:error, :element_exists} | {:error, any()}
  def add(room_id, media_identifier) do
    with :ok <- can_insert?(room_id, media_identifier),
         {:ok, res} when is_integer(res) <-
           Redis.List.push(build_key(room_id), media_identifier) do
      :ok
    end
  end

  @doc """
  Given a room id and a media identifier (generally a youtube id), removes the
  value from the room playlist.
  """
  @spec remove(Ecto.UUID.t(), String.t()) :: {:ok, :removed} | {:error, :noop}
  def remove(room_id, media_identifier) do
    case Redis.List.lrem(build_key(room_id), media_identifier) do
      {:ok, 0} ->
        {:error, :noop}

      {:ok, _n_removed} ->
        {:ok, :removed}
    end
  end

  @doc """
  Given a room id, a media identifier, an insertion condition and a target id,
  moves the media identifier to the new index in the list.
  """
  @spec move(Ecto.UUID.t(), String.t(), boolean(), String.t()) ::
          Redis.redix_response()
  def move(room_id, media_identifier, inserted_after?, target_id) do
    Redis.List.move(
      build_key(room_id),
      media_identifier,
      inserted_after?,
      target_id
    )
  end

  @doc """
  Given a room id returns a list of media ids that are currently added to
  the playlist.
  """
  @spec get(Ecto.UUID.t()) :: Redis.redix_response()
  def get(room_id) do
    Redis.List.range(build_key(room_id))
  end

  @doc """
  Given a room id and a media identifier checks the element existance in the
  list to return a result tuple.
  """
  @spec can_insert?(Ecto.UUID.t(), String.t()) ::
          :ok | {:error, :element_exists}
  def can_insert?(room_id, media_identifier) do
    case Redis.List.lpos(build_key(room_id), media_identifier) do
      {:ok, nil} ->
        :ok

      {:ok, _result} ->
        {:error, :element_exists}
    end
  end

  @doc """
  Given a room id and a media identifier, returns the previous media  if it
  exists in the playlist.
  """
  @spec get_previous(Ecto.UUID.t(), String.t()) ::
          {:ok, any()}
          | {:error, :previous_media_not_found | :error_getting_previous_media}
  def get_previous(room_id, media_identifier) do
    case get_position(build_key(room_id), media_identifier) do
      {:ok, nil} ->
        {:error, :previous_media_not_found}

      {:ok, 0} ->
        {:error, :previous_media_not_found}

      {:ok, position} when is_integer(position) ->
        get_media_by_index(build_key(room_id), position - 1)

      _error ->
        {:error, :error_getting_previous_media}
    end
  end

  @doc """
  Given a room id and a media identifier, returns the next media  if it exists
  in the playlist.
  """
  @spec get_next(Ecto.UUID.t(), String.t()) ::
          {:ok, any()}
          | {:error, :next_media_not_found | :error_getting_next_media}
  def get_next(room_id, media_identifier) do
    with {:ok, position} when is_integer(position) <-
           get_position(build_key(room_id), media_identifier),
         {:ok, length} <- get_length(build_key(room_id)) do
      if position < length - 1 do
        get_media_by_index(build_key(room_id), position + 1)
      else
        {:error, :next_media_not_found}
      end
    else
      {:ok, nil} ->
        {:error, :next_media_not_found}

      _error ->
        {:error, :error_getting_next_media}
    end
  end

  @spec get_length(Ecto.UUID.t()) :: Redis.redix_response()
  defp get_length(key), do: Redis.List.llen(key)

  @spec build_key(Ecto.UUID.t()) :: String.t()
  defp build_key(key), do: @key_prefix <> ":" <> key

  @spec get_position(Ecto.UUID.t(), any()) :: Redis.redix_response()
  defp get_position(key, element), do: Redis.List.lpos(key, element)

  @spec get_media_by_index(Ecto.UUID.t(), non_neg_integer()) ::
          Redis.redix_response()
  defp get_media_by_index(key, index), do: Redis.List.lindex(key, index)
end
