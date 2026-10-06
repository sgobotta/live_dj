defmodule LivedjWeb.PageHTML do
  @moduledoc false

  use LivedjWeb, :html

  embed_templates "page_html/*"

  # The headline rotator CSS (`.headline-rotator` in assets/css/app.css) assumes
  # exactly 10 phrases; page_controller_test.exs fails if the count changes.
  def headline_phrases do
    [
      gettext("Be the DJ of your friends' screen"),
      gettext("Your friends, your music, your rules."),
      gettext("Pass the aux. Everyone's watching."),
      gettext("Press play together."),
      gettext("Movie night, minus the argument over what to watch."),
      gettext("Drop the video. Own the room."),
      gettext("Every room needs a DJ. Why not you?"),
      gettext("Queue it up. Watch it together."),
      gettext("Watch YouTube together, in sync."),
      gettext("Your living room, wherever your friends are.")
    ]
  end
end
