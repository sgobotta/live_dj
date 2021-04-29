defmodule LiveDjWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use LiveDjWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint LiveDjWeb.Endpoint

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import LiveDjWeb.ConnCase

      alias LiveDjWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint LiveDjWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(LiveDj.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(LiveDj.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = LiveDj.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = LiveDj.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  @doc """
    Given a list of urls, builds and returns n live connections
  """
  def create_live_connections(urls) do
    for url <- urls do
      conn = build_conn()
      {:ok, _, _} = live_conn = live(conn, url)
      {conn, live_conn, url}
    end
  end

  @doc """
    Given a url, builds and returns n connections
  """
  def create_connections(url, n \\ 1) do
    for _ <- 0..(n - 1) do
      get(build_conn(), url)
    end
  end
end
