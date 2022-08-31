defmodule MrgrWeb.Live.NavBar do
  use MrgrWeb, :live_view

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)

      {:ok, assign(socket, :current_user, current_user)}
    else
      {:ok, assign(socket, :current_user, nil)}
    end
  end
end
