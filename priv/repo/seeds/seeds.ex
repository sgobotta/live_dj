defmodule Livedj.Seeds do
  @moduledoc """
  Interface for running fixture seeds per environment.
  """

  alias Livedj.Seeds

  @spec populate(atom()) :: :ok
  def populate(:dev) do
    :ok = Seeds.Dev.populate()
  end

  def populate(:test) do
    :ok = Seeds.Test.populate()
  end

  def populate(:prod) do
    :ok = Seeds.Prod.populate()
  end

  def populate(_env), do: :ok
end
