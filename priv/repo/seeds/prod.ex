defmodule Livedj.Seeds.Prod do
  @moduledoc """
  Runs development fixtures.
  """

  require Logger

  alias Livedj.Seeds.Accounts

  @spec populate :: :ok
  def populate do
    # Removes debug messages in this run
    :ok = Logger.configure(level: :info)

    :ok = Logger.info("📌 Starting seeds population process...")

    # Run seeds here
    :ok = Accounts.Users.populate()

    :ok = Logger.info("🌱 Finished seeds creation for prod environment.")

    :ok
  end
end
