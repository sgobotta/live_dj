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
  Creates a badge.

  ## Examples

      iex> create_badge(%{field: value})
      {:ok, %Badge{}}

      iex> create_badge(%{field: bad_value})
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

      iex> update_badge(badge, %{field: new_value})
      {:ok, %Badge{}}

      iex> update_badge(badge, %{field: bad_value})
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

      iex> assoc_user_badge(user_id, badge_id)
      :ok

      iex> assoc_user_badge(user_id)
      {:error,
       #Ecto.Changeset<
         action: :insert,
         changes: %{user_id: 1},
         errors: [badge_id: {"can't be blank", [validation: :required]}],
         data: #LiveDj.Accounts.UserBadge<>,
         valid?: false
       >}

  """
  def assoc_user_badge(user_id, badge_id) do
    association_result = UserBadge.changeset(
      %UserBadge{},
      %{user_id: user_id, badge_id: badge_id}
    )
    |> Repo.insert()
    case association_result do
      {:ok, _user} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end
end
