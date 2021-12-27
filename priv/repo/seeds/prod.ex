defmodule LiveDj.Seeds.Prod do
  @moduledoc """
  Runs prod fixtures.
  """
  require Logger

  @spec populate :: :ok
  def populate do
    try do
      seeds = [
        "permissions",
        "groups",
        "permissions_groups",
        "plans",
        "badges"
      ]

      for seed <- seeds do
        Code.require_file("#{seed}.exs", __DIR__)
      end
    rescue
      error ->
        :ok = Logger.error(error)
        :ok = Logger.info("❌ Stopped seeds population due to errors.")
    else
      _ ->
        :ok = Logger.info("🌱 Seeds population finished succesfully")
    end
  end
end
