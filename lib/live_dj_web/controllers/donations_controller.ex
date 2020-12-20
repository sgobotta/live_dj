defmodule LiveDjWeb.DonationsController do
  use LiveDjWeb, :controller

  alias LiveDj.Accounts
  alias LiveDj.Payments

  def index(conn, _params)   do
    render(conn, "index.html")
  end

  def new(conn, params) do
    %{"donation_id" => donation_id} = params
    %{assigns: %{current_user: current_user, visitor: visitor}} = conn

    case Payments.get_plan_by_plan_id(donation_id) do
      nil ->
        conn
          |> redirect(to: "/")
      plan ->
        IO.inspect("plan")
        IO.inspect(plan)

        # case Payments.create_order(user_params) do
        #   {:ok, order} ->
        #     IO.inspect("ORDER")
        #     IO.inspect(order)
        #     {:ok, _} =
        #       Payments.deliver_payment_confirmation(
        #         user,
        #         &Routes.user_confirmation_url(conn, :confirm, &1)
        #       )
        #   {:error, %Ecto.Changeset{} = changeset} ->
        #     render(conn, "new.html", changeset: changeset)
        # end


        conn
          |> redirect(to: "/donations/thanks")
    end

  end

  def thanks(conn, params) do
    %{assigns: %{current_user: current_user, visitor: visitor}} = conn
    case visitor do
      true ->
        render(conn, "new.html", username: "Guest")
      false ->
        render(conn, "new.html", username: current_user.username)
    end
  end
end
