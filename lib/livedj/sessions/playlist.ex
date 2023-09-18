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

  @spec build_key(Ecto.UUID.t()) :: String.t()
  defp build_key(key), do: @key_prefix <> ":" <> key
end
