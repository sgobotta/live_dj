defmodule LiveDj.Stats do
  @moduledoc """
  The Stats context.
  """

  import Ecto.Query, warn: false
  alias LiveDj.Repo

  alias LiveDj.Stats.Badge

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
  Associates an existing `%User{}`to an existing %Badge{}

  ## Examples

      iex> assoc_user_badge(user, badge)
      :ok

      iex> assoc_user_badge(user, badge)
      {:error, #Ecto.Changeset<action: nil, changes: %{...}, errors: [...], data: #LiveDj.Accounts.User<>, valid?: false>}

  """
  def assoc_user_badge(user, badge) do
    association_result = user
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:badges, [badge | user.badges])
    |> Repo.update()
    case association_result do
      {:ok, _user} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end
end
