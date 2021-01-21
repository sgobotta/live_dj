defmodule LiveDj.Stats do
  @moduledoc """
  The Stats context.
  """

  import Ecto.Query, warn: false
  alias LiveDj.Repo

  alias LiveDj.Stats.Badge
  alias LiveDj.Accounts.UserBadge

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
        badge_id: Repo.get_by(Badge, reference_name: badge_reference_name).id}
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
    badge

    # case badge do
    #   nil -> {:unchanged}
    #   badge -> create_badge()
    # end
  end
end
