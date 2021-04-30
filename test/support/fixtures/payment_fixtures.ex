defmodule LiveDj.PaymentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Payments` context.
  """

  alias LiveDj.AccountsFixtures

  def plan_fixture(attrs \\ %{}) do
    {:ok, plan} =
      attrs
      |> Enum.into(%{
        amount: 500.00,
        gateway: "mercadopago",
        name: "elite",
        plan_id: "123",
        type: "donation",
        extra: [%{"preference_id" => "asd123"}]
      })
      |> LiveDj.Payments.create_plan()

    plan
  end

  def order_fixture(attrs \\ %{}, user_attrs \\ %{}, plan_attrs \\ %{}) do
    plan = plan_fixture(plan_attrs)
    user = AccountsFixtures.user_fixture(user_attrs)

    {:ok, order} =
      attrs
      |> Enum.into(%{
        amount: 500.00,
        user_id: user.id,
        plan_id: plan.id
      })
      |> LiveDj.Payments.create_order()

    order
  end
end
