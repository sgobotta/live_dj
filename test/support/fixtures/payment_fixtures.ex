defmodule LiveDj.PaymentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Payments` context.
  """

  # def unique_user_username, do: "user#{System.unique_integer()}"

  # def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  # def valid_user_password, do: "hello world!"

  def plan_fixture(attrs \\ %{}) do
    {:ok, plan} =
      attrs
      |> Enum.into(%{
        amount: 500.00,
        gateway: "mercadopago",
        name: "elite",
        plan_id: "123",
        type: "donation"
      })
      |> LiveDj.Payments.create_plan()
    plan
  end

end
