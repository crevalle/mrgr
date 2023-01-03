defmodule MrgrWeb.Components.Live.JSONModalComponent do
  use MrgrWeb, :live_component

  def mount(socket) do
    button = socket.assigns[:button] || "Show"

    socket
    |> assign(:button, button)
    |> assign(:state, "closed")
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div>
      <.button
        phx-click="open"
        phx-target={@myself}
        class="bg-teal-700 hover:bg-teal-600 focus:ring-teal-500"
      >
        <%= @button %>
      </.button>
      <%= if @state == "open" do %>
        <div class="relative z-10" aria-labelledby="modal-title" role="dialog" aria-modal="true">
          <!--
          Background backdrop, show/hide based on modal state.

          Entering: "ease-out duration-300"
          From: "opacity-0"
          To: "opacity-100"
          Leaving: "ease-in duration-200"
          From: "opacity-100"
          To: "opacity-0"
          -->
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>

          <div class="fixed inset-0 z-10 overflow-y-auto">
            <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
              <!--
            Modal panel, show/hide based on modal state.

            Leaving: "ease-in duration-200"
            From: "opacity-100 translate-y-0 sm:scale-100"
            To: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            -->
              <div class="relative transform overflow-hidden rounded-lg bg-white px-4 pt-5 pb-4 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:p-6">
                <div>
                  <div class="mt-3 sm:mt-5">
                    <div class="flex items-center justify-between my-1">
                      <h3 class="text-lg font-medium leading-6 text-gray-900"><%= @title %></h3>
                      <div>
                        <button
                          phx-click="close"
                          phx-target={@myself}
                          class="inline-flex justify-center rounded-md border border-transparent bg-red-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 sm:text-sm"
                        >
                          Close
                        </button>
                        <.copy_button target={"#json-data-#{@id}"} />
                      </div>
                    </div>
                    <div class="mt-2">
                      <p class="text-sm text-gray-500">
                        <pre id={"json-data-#{@id}"}>
                          <%= Jason.encode!(@data, pretty: true) %>
                        </pre>
                      </p>
                    </div>
                  </div>
                </div>
                <div class="mt-5 sm:mt-6">
                  <button
                    phx-click="close"
                    phx-target={@myself}
                    class="inline-flex w-full justify-center rounded-md border border-transparent bg-red-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 sm:text-sm"
                  >
                    Close
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("open", _, socket) do
    {:noreply, assign(socket, :state, "open")}
  end

  def handle_event("close", _, socket) do
    {:noreply, assign(socket, :state, "closed")}
  end
end
