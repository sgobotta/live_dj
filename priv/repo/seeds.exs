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

Code.require_file("seeds/plans.exs", __DIR__)
Code.require_file("seeds/rooms.exs", __DIR__)
Code.require_file("seeds/users.exs", __DIR__)
Code.require_file("seeds/badges.exs", __DIR__)
