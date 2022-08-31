defmodule MrgrWeb.Live.WaitingListSignupForm do
  use MrgrWeb, :live_view

  alias Mrgr.Schema.WaitingListSignup

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :filled_out, false)}
  end

  def render(assigns) do
    ~H"""
      <%= if @filled_out do %>
        <p class="text-base text-gray-300 sm:text-xl lg:text-lg xl:text-xl">Thanks for your interest! We'll be in touch with news :)</p>
      <% else %>
        <.form let={f} for={:user} phx-submit="submit" class="sm:mx-aut- sm:max-w-xl lg:mx-0">
          <div class="sm:flex">
            <div class="min-w-0 flex-1">
              <%= label f, :email, class: "sr-only", id: "email-label", for: "email" %>
              <%= email_input f, :email, placeholder: "Enter your email", id: "email", class: "block w-full rounded-md border-0 px-4 py-3 text-base text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-cyan-400 focus:ring-offset-2 focus:ring-offset-gray-900" %>
            </div>
            <div class="mt-3 sm:mt-0 sm:ml-3">
              <button type="submit" class="block w-full rounded-md bg-gradient-to-r from-teal-500 to-cyan-600 py-3 px-4 font-medium text-white shadow hover:from-teal-600 hover:to-cyan-700 focus:outline-none focus:ring-2 focus:ring-cyan-400 focus:ring-offset-2 focus:ring-offset-gray-900">Join the waiting list</button>
            </div>
          </div>
        </.form>

      <% end %>
    """
  end

  def handle_event("submit", %{"user" => params}, socket) do
    %WaitingListSignup{}
    |> WaitingListSignup.changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, _signup} ->
        socket
        |> assign(:filled_out, true)
        |> noreply()

      {:error, _cs} ->
        noreply(socket)
    end
  end
end
