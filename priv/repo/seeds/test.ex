defmodule Livedj.Seeds.Test do
  @moduledoc """
  Runs test fixtures.
  """

  require Logger

  @spec populate :: :ok
  def populate do
    # Run seeds here
    :ok = Logger.info("🌱 No seeds available for test environment.")

    :ok
  end
end
