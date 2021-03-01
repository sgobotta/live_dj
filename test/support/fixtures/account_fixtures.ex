defmodule LiveDj.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Accounts` context.
  """

  alias LiveDj.Accounts

  def unique_user_username, do: "user#{System.unique_integer()}"

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        username: unique_user_username(),
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end

  def permission_fixture(attrs \\ %{}) do
    words = Faker.Lorem.words(2)
    valid_attrs = %{
      codename: Enum.join(words, "-"),
      name: Enum.join(words, " ")
    }
    {:ok, permission} =
      attrs
      |> Enum.into(valid_attrs)
      |> Accounts.create_permission()

    permission
  end

  def group_fixture(attrs \\ %{}) do
    words = Faker.Lorem.words(4)
    valid_attrs = %{
      codename: Enum.join(words, "-"),
      name: Enum.join(words, " ")
    }
    {:ok, group} =
      attrs
      |> Enum.into(valid_attrs)
      |> Accounts.create_group()

    group
  end

  def permission_group_fixture(attrs \\ %{}) do
    permission = permission_fixture()
    group = group_fixture()
    valid_attrs = %{permission_id: permission.id, group_id: group.id}
    {:ok, permission_group} =
      attrs
      |> Enum.into(valid_attrs)
      |> Accounts.create_permission_group()

      permission_group
  end

  @doc """
  Given a list of permission and a group id, creates as many permissions
  group relationships as the length of the given permission list.

  ## Examples

      iex> permissions_group_fixture(%{
        permissions: [%Permission{}, %Permission{}],
        group_id: 2
      }, %{extra_attribute: extra_value})
      {:ok, [%PermissionGroup{}, %PermissionGroup{}]}

  """
  def permissions_group_fixture(
      %{permissions: permissions, group_id: group_id},
      extra_attrs \\ %{}
  ) do
    mandatory_attrs = %{group_id: group_id}
    permissions_groups = permissions
    |> Enum.map(fn permission ->
      {:ok, permission_group} =
        extra_attrs
        |> Enum.into(Map.merge(mandatory_attrs, %{permission_id: permission.id}))
        |> Accounts.create_permission_group()
      permission_group
    end)
    {:ok, permissions_groups}
  end
end
