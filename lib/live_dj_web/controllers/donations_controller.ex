defmodule LiveDjWeb.DonationsController do
  use LiveDjWeb, :controller

  alias LiveDj.Payments

  def index(conn, _params)   do
    mercadopago_plans = Payments.get_mercadopago_plans()
    render(conn, "index.html", mercadopago_plans: mercadopago_plans)
  end

  def new(conn, params) do
    %{"donation_id" => donation_id} = params
    %{assigns: %{current_user: current_user, visitor: visitor}} = conn

    case Payments.get_plan_by_plan_id(donation_id) do
      nil ->
        conn
          |> redirect(to: "/")
      plan ->
        user_id = case visitor do
          true -> nil
          false -> current_user.id
        end

        case Payments.create_order(%{plan_id: plan.id, user_id: user_id}) do
          {:ok, _order} ->
            case visitor do
              false ->
                {:ok, _} = Payments.deliver_payment_confirmation(current_user)
              true -> nil
            end
            conn
            |> redirect(to: "/donations/thanks")
          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "new.html", changeset: changeset)
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
