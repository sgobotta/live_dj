# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LiveDj.Repo.insert!(%LiveDj.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias LiveDj.Repo
alias LiveDj.Payments.Plan

try do
  mercadopago_plans = System.get_env("MERCADOPAGO_PLANS")
    |> Poison.decode!()
    |> Enum.with_index()
    |> Enum.map(fn {plan, index} -> Repo.insert! %Plan{
      id: index + 1,
      amount: plan["amount"],
      gateway: plan["gateway"],
      name: plan["name"],
      plan_id: plan["plan_id"],
      type: plan["type"]
    } end)
rescue
  Ecto.ConstraintError -> IO.inspect("Plan seeds already exist in the database.")
  e -> IO.inspect("An error occurred while loading Plans seeds: #{e}")
after
  IO.inspect("Finished loading seeds.")
end
