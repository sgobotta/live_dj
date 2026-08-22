defmodule Livedj.Accounts.Guest do
  @moduledoc """
  Represents an unauthenticated visitor with a stable session identity.
  """

  @enforce_keys [:id, :username]
  defstruct [:id, :username]

  @type t :: %__MODULE__{id: binary(), username: binary()}

  @adjectives [
    &Faker.Commerce.product_name_material/0,
    &Faker.Pizza.style/0,
    &Faker.Cannabis.strain/0,
    &Faker.Superhero.power/0,
    &Faker.Commerce.color/0,
    &Faker.Superhero.descriptor/0
  ]

  @nouns [
    &Faker.StarWars.character/0,
    &Faker.Pokemon.name/0,
    &Faker.Food.spice/0,
    &Faker.Pizza.cheese/0,
    &Faker.StarWars.planet/0
  ]

  @spec random_username() :: binary()
  def random_username do
    adjective = Enum.random(@adjectives).()
    noun = Enum.random(@nouns).()
    camelize("#{adjective} #{noun}")
  end

  defp camelize(string) do
    case String.split(string, ~r/\s+/, trim: true) do
      [] ->
        ""

      [first | rest] ->
        Enum.join([
          String.downcase(first) | Enum.map(rest, &String.capitalize/1)
        ])
    end
  end
end
