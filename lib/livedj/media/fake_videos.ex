defmodule Livedj.Media.FakeVideos do
  @moduledoc """
  Curated list of placeholder videos shown in the search browse view
  before a query is submitted. Only used in the `:dev` environment.
  """

  alias Livedj.Media.Video

  @results [
    # ~5 second videos for player edge-case testing
    %Video{
      external_id: "QC8iQqtG0hg",
      title: "5 Second Video: Watch the Milky Way Rise",
      thumbnail_url: "https://i.ytimg.com/vi/QC8iQqtG0hg/hqdefault.jpg",
      etag: "fake"
    },
    %Video{
      external_id: "m9coOXt5nuw",
      title: "5 Second Video Ad (sample 2)",
      thumbnail_url: "https://i.ytimg.com/vi/m9coOXt5nuw/hqdefault.jpg",
      etag: "fake"
    },
    # 70s rock
    %Video{
      external_id: "fJ9rUzIMcZQ",
      title: "Queen - Bohemian Rhapsody",
      thumbnail_url: "https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg",
      etag: "fake"
    },
    # 70s prog rock
    %Video{
      external_id: "_FrOQC-zEog",
      title: "Pink Floyd - Comfortably Numb",
      thumbnail_url: "https://i.ytimg.com/vi/_FrOQC-zEog/hqdefault.jpg",
      etag: "fake"
    },
    # 70s rock
    %Video{
      external_id: "HQmmM_qwG4k",
      title: "Led Zeppelin - Whole Lotta Love",
      thumbnail_url: "https://i.ytimg.com/vi/HQmmM_qwG4k/hqdefault.jpg",
      etag: "fake"
    },
    # 80s rock
    %Video{
      external_id: "1w7OgIMMRc4",
      title: "Guns N' Roses - Sweet Child O' Mine",
      thumbnail_url: "https://i.ytimg.com/vi/1w7OgIMMRc4/hqdefault.jpg",
      etag: "fake"
    },
    # 80s rock
    %Video{
      external_id: "wTP2RUD_cL0",
      title: "Dire Straits - Money for Nothing",
      thumbnail_url: "https://i.ytimg.com/vi/wTP2RUD_cL0/hqdefault.jpg",
      etag: "fake"
    },
    # prog rock
    %Video{
      external_id: "auLBLk4ibAk",
      title: "Rush - Tom Sawyer",
      thumbnail_url: "https://i.ytimg.com/vi/auLBLk4ibAk/hqdefault.jpg",
      etag: "fake"
    },
    # vulfpeck
    %Video{
      external_id: "le0BLAEO93g",
      title: "Vulfpeck - Dean Town",
      thumbnail_url: "https://i.ytimg.com/vi/le0BLAEO93g/hqdefault.jpg",
      etag: "fake"
    },
    # vulfpeck / cory wong
    %Video{
      external_id: "F7nCDrf90V8",
      title: "VULFPECK /// Disco Ulysses (Instrumental)",
      thumbnail_url: "https://i.ytimg.com/vi/F7nCDrf90V8/hqdefault.jpg",
      etag: "fake"
    },
    # cory wong
    %Video{
      external_id: "HuRaGMyCb2Q",
      title: "Cory Wong // \"Smooth Move\" (feat. Tom Misch)",
      thumbnail_url: "https://i.ytimg.com/vi/HuRaGMyCb2Q/hqdefault.jpg",
      etag: "fake"
    }
  ]

  @spec results() :: [Video.t()]
  def results, do: @results
end
