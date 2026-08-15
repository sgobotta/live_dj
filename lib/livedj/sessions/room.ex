defmodule Livedj.Sessions.Room do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @password_min 4
  @password_max 32

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :name, :string
    field :slug, :string
    field :password_hash, :string
    field :password, :string, virtual: true, redact: true

    timestamps()
  end

  @doc """
  Changeset for creating/updating a room. Casts an optional `:password`; a
  non-blank value is validated and hashed into `:password_hash`, a blank/absent
  value leaves the room public.
  """
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :password])
    |> validate_required([:name])
    |> maybe_put_slug()
    |> maybe_hash_password()
  end

  @doc """
  Changeset dedicated to editing the password from the room page. A blank value
  clears protection (`password_hash` -> nil); a non-blank value is validated and
  hashed.
  """
  def password_changeset(room, attrs) do
    room
    |> cast(attrs, [:password], empty_values: [])
    |> clear_or_hash_password()
  end

  @doc """
  Changeset dedicated to editing the room name from the room settings page.
  """
  def name_changeset(room, attrs) do
    room
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  defp maybe_hash_password(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      "" -> delete_change(changeset, :password)
      _password -> put_password_hash(changeset)
    end
  end

  defp clear_or_hash_password(changeset) do
    case get_change(changeset, :password) do
      blank when blank in [nil, ""] ->
        put_change(changeset, :password_hash, nil)

      _password ->
        put_password_hash(changeset)
    end
  end

  defp put_password_hash(changeset) do
    changeset =
      validate_length(changeset, :password,
        min: @password_min,
        max: @password_max,
        count: :codepoints
      )

    if changeset.valid? do
      changeset
      |> put_change(
        :password_hash,
        Bcrypt.hash_pwd_salt(get_change(changeset, :password))
      )
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_put_slug(%Ecto.Changeset{data: %{slug: nil}} = changeset) do
    put_change(changeset, :slug, Ecto.UUID.generate())
  end

  defp maybe_put_slug(changeset), do: changeset
end
