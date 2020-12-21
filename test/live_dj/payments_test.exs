defmodule LiveDj.PaymentsTest do
  use LiveDj.DataCase

  alias LiveDj.Payments

  import LiveDj.AccountsFixtures
  import LiveDj.PaymentsFixtures

  describe "plans" do
    alias LiveDj.Payments.Plan

    @valid_attrs %{amount: 120.5, gateway: "some gateway", name: "some name", plan_id: "some plan_id", type: "some type"}
    @update_attrs %{amount: 456.7, gateway: "some updated gateway", name: "some updated name", plan_id: "some updated plan_id", type: "some updated type"}
    @invalid_attrs %{amount: nil, gateway: nil, name: nil, plan_id: nil, type: nil}

    def _plan_fixture(attrs \\ %{}) do
      {:ok, plan} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Payments.create_plan()

      plan
    end

    test "list_plans/0 returns all plans" do
      plan = _plan_fixture()
      assert Payments.list_plans() == [plan]
    end

    test "get_plan!/1 returns the plan with given id" do
      plan = _plan_fixture()
      assert Payments.get_plan!(plan.id) == plan
    end

    test "create_plan/1 with valid data creates a plan" do
      assert {:ok, %Plan{} = plan} = Payments.create_plan(@valid_attrs)
      assert plan.amount == 120.5
      assert plan.gateway == "some gateway"
      assert plan.name == "some name"
      assert plan.plan_id == "some plan_id"
      assert plan.type == "some type"
    end

    test "create_plan/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Payments.create_plan(@invalid_attrs)
    end

    test "update_plan/2 with valid data updates the plan" do
      plan = _plan_fixture()
      assert {:ok, %Plan{} = plan} = Payments.update_plan(plan, @update_attrs)
      assert plan.amount == 456.7
      assert plan.gateway == "some updated gateway"
      assert plan.name == "some updated name"
      assert plan.plan_id == "some updated plan_id"
      assert plan.type == "some updated type"
    end

    test "update_plan/2 with invalid data returns error changeset" do
      plan = _plan_fixture()
      assert {:error, %Ecto.Changeset{}} = Payments.update_plan(plan, @invalid_attrs)
      assert plan == Payments.get_plan!(plan.id)
    end

    test "delete_plan/1 deletes the plan" do
      plan = _plan_fixture()
      assert {:ok, %Plan{}} = Payments.delete_plan(plan)
      assert_raise Ecto.NoResultsError, fn -> Payments.get_plan!(plan.id) end
    end

    test "change_plan/1 returns a plan changeset" do
      plan = _plan_fixture()
      assert %Ecto.Changeset{} = Payments.change_plan(plan)
    end
  end

  describe "orders" do
    alias LiveDj.Payments.Order

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{plan_id: nil}

    setup do
      user = user_fixture()
      plan = plan_fixture()

      %{user: user, plan: plan}
    end

    def order_fixture(attrs \\ %{}) do
      {:ok, order} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Payments.create_order()

      order
    end

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Payments.list_orders() == [order]
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Payments.get_order!(order.id) == order
    end

    test "create_order/1 with valid data creates an order", %{plan: plan} do
      assert {:ok, %Order{} = order} = Payments.create_order(%{plan_id: plan.id})
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Payments.create_order(@invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()
      assert {:ok, %Order{} = order} = Payments.update_order(order, @update_attrs)
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = order_fixture()
      assert {:error, %Ecto.Changeset{}} = Payments.update_order(order, @invalid_attrs)
      assert order == Payments.get_order!(order.id)
    end

    test "delete_order/1 deletes the order" do
      order = order_fixture()
      assert {:ok, %Order{}} = Payments.delete_order(order)
      assert_raise Ecto.NoResultsError, fn -> Payments.get_order!(order.id) end
    end

    test "change_order/1 returns a order changeset" do
      order = order_fixture()
      assert %Ecto.Changeset{} = Payments.change_order(order)
    end
  end
end
