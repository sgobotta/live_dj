# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LiveDj.Repo.insert!(%LiveDj.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

try do
  seeds = [
    "permissions",
    "groups",
    "permissions_groups",
    "plans",
    "rooms",
    "users",
    "users_rooms",
    "badges",
    "badges_relations"
  ]
  for seed <- seeds do
    Code.require_file("seeds/#{seed}.exs", __DIR__)
  end
rescue
  _error ->
    IO.inspect("Stopped seeds population due to errors.")
end
