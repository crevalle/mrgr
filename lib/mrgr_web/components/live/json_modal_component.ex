defmodule MrgrWeb.Components.Live.JSONModalComponent do
  use MrgrWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, state: "closed")}
  end

  def render(assigns) do
    ~H"""

    <div>
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
                    <h3 class="text-lg font-medium leading-6 text-gray-900"><%= @title %></h3>
                    <div class="mt-2">
                      <p class="text-sm text-gray-500">
                        <pre>
                          <%= Jason.encode!(@data, pretty: true) %>
                        </pre>
                      </p>
                    </div>
                  </div>
                </div>
                <div class="mt-5 sm:mt-6">
                  <button
                    phx-click="hide-modal"
                    phx-value-id={@id}
                    class="inline-flex w-full justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:text-sm"
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
    {:noreply, assign(socket, :state, "OPEN")}
  end

  def handle_event("close", _, socket) do
    {:noreply, assign(socket, :state, "CLOSED")}
  end
end
