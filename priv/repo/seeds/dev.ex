defmodule LiveDj.Seeds.Dev do
  @moduledoc """
  Runs development fixtures.
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
        "rooms",
        "videos",
        "users",
        "users_rooms",
        "badges",
        "badges_relations",
        "users_videos",
        "playlists",
        "room_playlists_videos"
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
