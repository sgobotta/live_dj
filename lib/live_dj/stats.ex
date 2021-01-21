defmodule LiveDj.Stats do
  @moduledoc """
  The Stats context.
  """

  import Ecto.Query, warn: false
  alias LiveDj.Repo

  alias LiveDj.Stats.{Badge, UserBadge}

  @doc """
  Returns the list of badges.

  ## Examples

      iex> list_badges()
      [%Badge{}, ...]

  """
  def list_badges do
    Repo.all(Badge)
  end

  @doc """
  Gets a single badge.

  Raises `Ecto.NoResultsError` if the Badge does not exist.

  ## Examples

      iex> get_badge!(123)
      %Badge{}

      iex> get_badge!(456)
      ** (Ecto.NoResultsError)

  """
  def get_badge!(id), do: Repo.get!(Badge, id)

  @doc """
  Given a set of values, returns true if a UserBadge exists.

  ## Examples

      iex> has_badge_by(1, 1)
      true

      iex> has_badge_by(100, 13)
      false

  """
  def has_badge_by(user_id, badge_id) do
    from(ub in UserBadge,
      where:
        ub.user_id == ^user_id and
        ub.badge_id == ^badge_id
    ) |> Repo.exists?()
  end

  @doc """
  Creates a badge.

  ## Examples

      iex> create_badge(%{user_id: user_id, badge_id: badge_id})
      {:ok, %Badge{}}

      iex> create_badge(%{user_id: user_id})
      {:error, %Ecto.Changeset{}}

  """
  def create_badge(attrs \\ %{}) do
    %Badge{}
    |> Badge.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a badge.

  ## Examples

      iex> update_badge(badge, %{user_id: user_id, badge_id: badge_id})
      {:ok, %Badge{}}

      iex> update_badge(badge, %{user_id: user_id})
      {:error, %Ecto.Changeset{}}

  """
  def update_badge(%Badge{} = badge, attrs) do
    badge
    |> Badge.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a badge.

  ## Examples

      iex> delete_badge(badge)
      {:ok, %Badge{}}

      iex> delete_badge(badge)
      {:error, %Ecto.Changeset{}}

  """
  def delete_badge(%Badge{} = badge) do
    Repo.delete(badge)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking badge changes.

  ## Examples

      iex> change_badge(badge)
      %Ecto.Changeset{data: %Badge{}}

  """
  def change_badge(%Badge{} = badge, attrs \\ %{}) do
    Badge.changeset(badge, attrs)
  end

  @doc """
  Associates an existing `%User{}`to an existing %Badge{} by inserting a
  %UserBadge{} entity.

  ## Examples

      iex> assoc_user_badge(user_id, badge_reference_name)
      :ok

  """
  def assoc_user_badge(user_id, badge_reference_name) do
    association_result = UserBadge.changeset(
      %UserBadge{},
      %{
        user_id: user_id,
        badge_id: Repo.get_by(Badge, reference_name: badge_reference_name).id
      }
    )
    |> Repo.insert()
    case association_result do
      {:ok, _user} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Given a user_id and a rooms_length Associates an existing `%User{}`to an existing %Badge{} by inserting a
  %UserBadge{} entity.

  ## Examples

      iex> assoc_user_badge("rooms-creation", 1, 2)
      :ok

  """
  def assoc_user_badge("rooms-creation", user_id, rooms_length) do
    badge = from(b in Badge,
      where:
        b.type == "rooms-creation" and
        b.checkpoint == ^rooms_length
    ) |> Repo.one()

    case badge do
      nil -> {:unchanged}
      badge ->
        {:ok, create_user_badge(%{user_id: user_id, badge_id: badge.id})}
    end
  end

  @doc """
  Returns the list of users_badges.

  ## Examples

      iex> list_users_badges()
      [%UserBadge{}, ...]

  """
  def list_users_badges do
    Repo.all(UserBadge)
  end

  @doc """
  Gets a single user_badge.

  Raises `Ecto.NoResultsError` if the User badge does not exist.

  ## Examples

      iex> get_user_badge!(123)
      %UserBadge{}

      iex> get_user_badge!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_badge!(id), do: Repo.get!(UserBadge, id)

  @doc """
  Creates a user_badge.

  ## Examples

      iex> create_user_badge(%{user_id: 1, badge_id: 1})
      {:ok, %UserBadge{}}

      iex> create_user_badge(%{user_id: bad_value, badge_id: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_badge(attrs \\ %{}) do
    %UserBadge{}
    |> UserBadge.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_badge.

  ## Examples

      iex> update_user_badge(user_badge, %{user_id: 1, badge_id: 1})
      {:ok, %UserBadge{}}

      iex> update_user_badge(user_badge, %{user_id: bad_value, badge_id: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_badge(%UserBadge{} = user_badge, attrs) do
    user_badge
    |> UserBadge.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_badge.

  ## Examples

      iex> delete_user_badge(user_badge)
      {:ok, %UserBadge{}}

      iex> delete_user_badge(user_badge)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_badge(%UserBadge{} = user_badge) do
    Repo.delete(user_badge)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_badge changes.

  ## Examples

      iex> change_user_badge(user_badge)
      %Ecto.Changeset{data: %UserBadge{}}

  """
  def change_user_badge(%UserBadge{} = user_badge, attrs \\ %{}) do
    UserBadge.changeset(user_badge, attrs)
  end
end
