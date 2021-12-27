defmodule LiveDjWeb.MountHelpers do
  @moduledoc false

  import Phoenix.LiveView

  alias LiveDj.Accounts
  alias LiveDj.Accounts.User

  def assign_defaults(socket, _params, session) do
    socket
    |> assign_current_user(session)
    |> assign_initial_changesets()
  end

  defp assign_initial_changesets(socket) do
    %{current_user: current_user, visitor: visitor} = socket.assigns

    case visitor do
      true ->
        socket
        |> assign(
          :user_changeset,
          Accounts.change_user_registration(%User{}, current_user)
        )

      false ->
        socket
        |> assign(:user_changeset, Accounts.change_user_username(%User{}))
    end
  end

  defp assign_current_user(socket, session) do
    user = LiveDj.Accounts.get_user_by_session_token(session["user_token"])

    %{user: user, visitor: visitor} =
      case user do
        nil -> %{user: %{username: create_random_name()}, visitor: true}
        user -> %{user: user, visitor: false}
      end

    socket
    |> assign_new(:current_user, fn -> user end)
    |> assign_new(:visitor, fn -> visitor end)
  end

  defp create_random_name do
    adjectives = [
      fn -> Faker.Superhero.descriptor() end,
      fn -> Faker.Pizza.cheese() end,
      fn -> Faker.Pizza.style() end,
      fn -> Faker.Commerce.product_name_material() end,
      fn -> Faker.Cannabis.strain() end,
      fn -> Faker.Commerce.product_name_adjective() end
    ]

    nouns = [
      fn -> Faker.StarWars.character() end,
      fn -> Faker.Pokemon.name() end,
      fn -> Faker.Food.ingredient() end,
      fn -> Faker.Superhero.name() end
    ]

    descriptor = Enum.at(adjectives, Enum.random(0..(length(adjectives) - 1)))
    name = Enum.at(nouns, Enum.random(0..(length(nouns) - 1)))
    "#{descriptor.()} #{name.()}"
  end
end
