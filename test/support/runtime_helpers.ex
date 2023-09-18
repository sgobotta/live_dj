defmodule Livedj.RuntimeHelpers do
  @moduledoc """
  This module defines helpers for tests that require runtime utils or tuning.
  """

  @doc """
  Returns a blocked process that listens to messages
  """
  def client_mock do
    receive do
      _message -> nil
    after
      5000 -> :timeout
    end

    client_mock()
  end

  @doc """
  Given an integer, returns a list of pid, user tuples
  """
  @spec spawn_client(pos_integer()) ::
          list({pid(), Livedj.Accounts.User.t()})
  def spawn_client(n) do
    Enum.map(1..n, fn _n ->
      pid = spawn(fn -> client_mock() end)
      # Enables messages tracing going through pid
      :erlang.trace(pid, true, [:receive])

      {pid, Livedj.AccountsFixtures.user_fixture()}
    end)
  end
end
