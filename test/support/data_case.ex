defmodule LiveDj.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use LiveDj.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias LiveDj.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import LiveDj.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(LiveDj.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(LiveDj.Repo, {:shared, self()})
    end

    :ok
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  import LiveDj.AccountsFixtures

  @doc """
  A helper that initialises the needed data for a show live view
  """
  def show_live_setup do
    # Creates some mandatory groups
    group_fixture(%{
      codename: "anonymous-room-visitor",
      name: "Anonymous room visitor"
    })
    group_fixture(%{
      codename: "registered-room-visitor",
      name: "Registered room visitor"
    })
    # Creates an initial group
    group = group_fixture()
    # Just creates 3 permissions and associates them to a group
    permissions = for _n <- 1..3, do: permission_fixture()
    {:ok, _permission_group} = permissions_group_fixture(%{
      permissions: permissions,
      group_id: group.id
    })

    %{group: group}
  end
end
