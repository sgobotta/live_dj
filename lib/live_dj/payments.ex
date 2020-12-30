defmodule LiveDj.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false
  alias LiveDj.Repo

  alias LiveDj.Accounts.{User, UserNotifier}
  alias LiveDj.Payments.Plan

  @doc """
  Returns the list of plans.

  ## Examples

      iex> list_plans()
      [%Plan{}, ...]

  """
  def list_plans do
    Repo.all(Plan)
  end

  @doc """
  Gets a single plan.

  Raises `Ecto.NoResultsError` if the Plan does not exist.

  ## Examples

      iex> get_plan!(123)
      %Plan{}

      iex> get_plan!(456)
      ** (Ecto.NoResultsError)

  """
  def get_plan!(id), do: Repo.get!(Plan, id)

  @doc """
  Gets a plan by plan_id.

  Raises `Ecto.NoResultsError` if the Plan does not exist.

  ## Examples

      iex> get_plan_by_id!(123)
      %Plan{}

      iex> get_plan_by_id!(456)
      ** (Ecto.NoResultsError)

  """
  def get_plan_by_plan_id(plan_id), do: Repo.get_by(Plan, plan_id: plan_id)

  @doc """
  Creates a plan.

  ## Examples

      iex> create_plan(%{field: value})
      {:ok, %Plan{}}

      iex> create_plan(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_plan(attrs \\ %{}) do
    %Plan{}
    |> Plan.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a plan.

  ## Examples

      iex> update_plan(plan, %{field: new_value})
      {:ok, %Plan{}}

      iex> update_plan(plan, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_plan(%Plan{} = plan, attrs) do
    plan
    |> Plan.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a plan.

  ## Examples

      iex> delete_plan(plan)
      {:ok, %Plan{}}

      iex> delete_plan(plan)
      {:error, %Ecto.Changeset{}}

  """
  def delete_plan(%Plan{} = plan) do
    Repo.delete(plan)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking plan changes.

  ## Examples

      iex> change_plan(plan)
      %Ecto.Changeset{data: %Plan{}}

  """
  def change_plan(%Plan{} = plan, attrs \\ %{}) do
    Plan.changeset(plan, attrs)
  end

  def get_mercadopago_plans() do
    list_plans()
    |> Enum.filter(fn p -> p.gateway == "mercadopago" end)
    |> Enum.map(
      fn p ->
        Map.merge(p, %{preference_id: hd(p.extra)["preference_id"], amount: floor(p.amount)})
        |> Map.drop([:extra, :plan_id])
      end)
  end

  def get_paypal_plans() do
    list_plans()
    |> Enum.filter(fn p -> p.gateway == "paypal" end)
    |> Enum.map(
      fn p ->
        Map.merge(p, %{input_value: hd(p.extra)["input_value"], host: hd(p.extra)["host"], amount: floor(p.amount)})
        |> Map.drop([:extra, :plan_id])
      end)
  end

  alias LiveDj.Payments.Order

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders()
      [%Order{}, ...]

  """
  def list_orders do
    Repo.all(Order)
  end

  def list_user_orders(id) do
    from(
      order in Order,
      where: order.user_id == ^id,
      order_by: [desc: order.inserted_at],
      join: plan in Plan, on: order.plan_id == plan.id,
      select: %{
        amount: order.amount,
        inserted_at: order.inserted_at,
        plan: %{gateway: plan.gateway, name: plan.name, type: plan.type}
      }
    )
    |> Repo.all()
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(123)
      %Order{}

      iex> get_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(id), do: Repo.get!(Order, id)

  def has_order_by_user_id(id) do
    Repo.exists?(Order, user_id: id)
  end

  @doc """
  Creates a order.

  ## Examples

      iex> create_order(%{field: value})
      {:ok, %Order{}}

      iex> create_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a order.

  ## Examples

      iex> delete_order(order)
      {:ok, %Order{}}

      iex> delete_order(order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{data: %Order{}}

  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  @doc """
  Delivers the payment confirmation email to the given user.

  ## Examples

      iex> deliver_payment_confirmation(user)
      {:ok, %{to: ..., body: ...}}
  """
  def deliver_payment_confirmation(%User{} = user) do
    UserNotifier.deliver_payment_confirmation(user)
  end
end
