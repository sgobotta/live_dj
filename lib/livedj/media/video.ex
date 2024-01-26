defmodule Livedj.Media.Video do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import LivedjWeb.Gettext

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "videos" do
    field :etag, :string
    field :external_id, :string
    field :published_at, :naive_datetime
    field :thumbnail_url, :string
    field :title, :string
    field :channel, :string

    timestamps()
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :channel,
      :title,
      :thumbnail_url,
      :external_id,
      :etag,
      :published_at
    ])
    |> validate_required([
      :channel,
      :title,
      :thumbnail_url,
      :external_id,
      :published_at
    ])
    |> unique_constraint(:external_id,
      message: dgettext("errors", "video with this id already exists")
    )
  end

  @spec from_struct(t()) :: map()
  def from_struct(%__MODULE__{
        id: id,
        channel: channel,
        etag: etag,
        external_id: external_id,
        published_at: published_at,
        thumbnail_url: thumbnail_url,
        title: title,
        inserted_at: inserted_at,
        updated_at: updated_at
      }),
      do: %{
        id: id,
        channel: channel,
        etag: etag,
        external_id: external_id,
        published_at: published_at,
        thumbnail_url: thumbnail_url,
        title: title,
        inserted_at: inserted_at,
        updated_at: updated_at
      }

  @spec from_hset(map()) :: t()
  def from_hset(hset),
    do:
      Enum.reduce(hset, %__MODULE__{}, fn {k, v}, acc ->
        key = String.to_atom(k)
        Map.put(acc, key, parse_hset_value(key, v))
      end)

  @spec parse_hset_value(atom(), any()) :: any()
  defp parse_hset_value(_key, value), do: value
end
