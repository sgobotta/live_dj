defmodule Redis.PubSub do
  @moduledoc false

  def start do
    Redix.PubSub.start_link(Redis.Application.opts())
  end

  def susbcribe(pubsub, channel, subscriber) do
    Redix.PubSub.subscribe(pubsub, channel, subscriber)
  end

  def publish(channel, message) do
    Redix.command!(:redix, ~w(PUBLISH #{channel} #{message}))
  end
end
