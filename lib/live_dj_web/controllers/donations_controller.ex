defmodule LiveDjWeb.DonationsController do
  use LiveDjWeb, :controller

  alias LiveDj.Payments

  def index(conn, _params) do
    %{assigns: %{visitor: visitor}} = conn
    mercadopago_plans = Payments.get_mercadopago_plans()
    paypal_plans = Payments.get_paypal_plans()
    conn = case visitor do
      true -> put_flash(conn, :info, "We're working on extra features and visuals. You can donate as a guest user but we recommend donating as a registered user to receive exclusive content.")
      false -> put_flash(conn, :info, "Receive a donor badge by contributing to this project.")
    end

    render(
      conn,
      "index.html",
      mercadopago_plans: mercadopago_plans, paypal_plans: paypal_plans
    )
  end

  def new(conn, params) do
    %{"donation_id" => donation_id} = params

    donation_id = case donation_id do
      "paypal_completed" ->
        [attr, id, _] = Poison.decode!(System.get_env("PAYPAL_ATTRS"))
        Poison.decode!(params[attr])[id]
      "mercadopago_completed" ->
        params[System.get_env("MERCADOPAGO_ATTR")]
      _ -> ""
    end

    %{assigns: %{current_user: current_user, visitor: visitor}} = conn

    case Payments.get_plan_by_plan_id(donation_id) do
      nil -> redirect(conn, to: "/#{params["donation_id"]}")
      plan ->
        user_id = case visitor do
          true -> nil
          false -> current_user.id
        end

        amount = case plan.gateway do
          "mercadopago" -> plan.amount
          "paypal" ->
            [_, _, amount] = Poison.decode!(System.get_env("PAYPAL_ATTRS"))
            {amount, _} = Float.parse(params[amount])
            amount
        end

        case Payments.create_order(%{
          amount: amount,
          plan_id: plan.id,
          user_id: user_id
        }) do
          {:ok, _order} ->
            case visitor do
              false ->
                {:ok, _} = Payments.deliver_payment_confirmation(current_user)
              true -> nil
            end
            conn
            |> redirect(to: "/donations/thanks")
          {:error, %Ecto.Changeset{} = _changeset} ->
            # Log this error to manually fix up potential errors.
            # Payment has been made but it was not registered.
            conn
            |> redirect(to: "/donations/thanks")
        end
    end
  end

  def thanks(conn, _params) do
    %{assigns: %{current_user: current_user, visitor: visitor}} = conn
    case visitor do
      true ->
        render(conn, "new.html", username: "Guest")
      false ->
        render(conn, "new.html", username: current_user.username)
    end
  end
end
