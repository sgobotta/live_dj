alias LiveDj.Repo
alias LiveDj.Payments.Plan

try do
  datetime = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  mercadopago_plans = System.get_env("MERCADOPAGO_PLANS")
    |> Poison.decode!()
    |> Enum.with_index()
    |> Enum.map(fn {plan, index} -> %{
      id: index + 1,
      amount: plan["amount"],
      gateway: plan["gateway"],
      name: plan["name"],
      plan_id: plan["plan_id"],
      type: plan["type"],
      extra: [%{preference_id: plan["preference_id"]}],
      inserted_at: datetime,
      updated_at: datetime
    } end)

  paypal_plans = System.get_env("PAYPAL_PLANS")
    |> Poison.decode!()
    |> Enum.with_index(length(mercadopago_plans))
    |> Enum.map(fn {plan, index} -> %{
      id: index + 1,
      amount: plan["amount"],
      gateway: plan["gateway"],
      name: plan["name"],
      plan_id: plan["plan_id"],
      type: plan["type"],
      extra: [%{input_value: plan["input_value"]}],
      inserted_at: datetime,
      updated_at: datetime
    } end)

  {count, _} = Repo.insert_all(Plan, mercadopago_plans ++ paypal_plans)
  IO.inspect("Inserted #{count} plans.")

rescue
  Postgrex.Error ->
    IO.inspect("Plan seeds were already loaded in the database. Skipping execution.")
  error ->
    IO.inspect("Unexpected error while loading Plan seeds.")
    IO.inspect(error)
end
