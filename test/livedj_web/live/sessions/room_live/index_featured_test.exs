defmodule LivedjWeb.Sessions.RoomLive.IndexFeaturedTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Livedj.Sessions.Room
  alias LivedjWeb.Sessions.RoomLive.Index

  defp entry(id, user_count, inserted_at) do
    %{
      id: id,
      room: %Room{id: id, name: "room-#{id}", inserted_at: inserted_at},
      player: nil,
      users: List.duplicate(%{username: "u"}, user_count)
    }
  end

  defp at(iso), do: NaiveDateTime.from_iso8601!(iso)

  describe "featured_and_rest/1" do
    test "returns {nil, []} when there are no rooms" do
      assert {nil, []} = Index.featured_and_rest([])
    end

    test "features the room with the most present users" do
      a = entry("a", 1, at("2026-01-01T00:00:00"))
      b = entry("b", 5, at("2026-01-02T00:00:00"))
      c = entry("c", 2, at("2026-01-03T00:00:00"))

      assert {^b, rest} = Index.featured_and_rest([a, b, c])
      assert Enum.map(rest, & &1.id) == ["a", "c"]
    end

    test "keeps the non-featured rooms in their original order" do
      a = entry("a", 3, at("2026-01-01T00:00:00"))
      b = entry("b", 1, at("2026-01-02T00:00:00"))
      c = entry("c", 1, at("2026-01-03T00:00:00"))

      assert {^a, [^b, ^c]} = Index.featured_and_rest([a, b, c])
    end

    test "falls back to the newest room when every room is empty" do
      a = entry("a", 0, at("2026-01-01T00:00:00"))
      b = entry("b", 0, at("2026-01-03T00:00:00"))
      c = entry("c", 0, at("2026-01-02T00:00:00"))

      assert {%{id: "b"}, _rest} = Index.featured_and_rest([a, b, c])
    end

    test "breaks ties among populated rooms by newest" do
      a = entry("a", 4, at("2026-01-01T00:00:00"))
      b = entry("b", 4, at("2026-01-05T00:00:00"))

      assert {%{id: "b"}, _rest} = Index.featured_and_rest([a, b])
    end

    test "features the only room when there is a single one" do
      a = entry("a", 0, at("2026-01-01T00:00:00"))

      assert {^a, []} = Index.featured_and_rest([a])
    end
  end

  describe "sort_by_users/1" do
    test "sorts rooms by present user count, descending" do
      a = entry("a", 1, at("2026-01-01T00:00:00"))
      b = entry("b", 5, at("2026-01-02T00:00:00"))
      c = entry("c", 2, at("2026-01-03T00:00:00"))

      assert Index.sort_by_users([a, b, c]) |> Enum.map(& &1.id) ==
               ["b", "c", "a"]
    end

    test "breaks ties by keeping original relative order (stable sort)" do
      a = entry("a", 1, at("2026-01-01T00:00:00"))
      b = entry("b", 3, at("2026-01-02T00:00:00"))
      c = entry("c", 1, at("2026-01-03T00:00:00"))
      d = entry("d", 3, at("2026-01-04T00:00:00"))

      assert Index.sort_by_users([a, b, c, d]) |> Enum.map(& &1.id) ==
               ["b", "d", "a", "c"]
    end

    test "returns an empty list for an empty list" do
      assert Index.sort_by_users([]) == []
    end
  end
end
