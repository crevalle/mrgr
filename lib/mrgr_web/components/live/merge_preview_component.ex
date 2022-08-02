defmodule MrgrWeb.Components.Live.MergePreviewComponent do
  use MrgrWeb, :live_component
  use Mrgr.PubSub.Event

  def render(%{merge: nil} = assigns) do
    ~H"""
    <div></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="basis-1/2 p-4 bg-white overflow-hidden shadow rounded-lg">
      <div class="flex flex-col space-y-4">
        <div class="flex items-start items-center">
          <.h3><%= @merge.title %></.h3>
          <%= link to: external_merge_url(@merge), target: "_blank" do %>
            <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg"  fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
            </svg>
          <% end %>
        </div>

        <.form let={f} for={:merge}, phx-submit="merge", phx-target={@myself}, class="flex flex-col space-y-4">
          <%= label f, :message, "Commit Message", class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1">
            <%= textarea f, :message, placeholder: "Commit message defaults to PR title.  Enter additional info here.", rows: "4", class: "shadow-sm focus:ring-emerald-500 focus:border-emerald-500 block w-full sm:text-sm border-gray-300 rounded-md"  %>
          </div>
          <%= hidden_input f, :id, value: @merge.id %>
          <div class="flex items-end">
            <.button submit={true} phx_disable_with="Merging...">Merge!</.button>
          </div>
        </.form>

        <div>
          <.h3>Files Changed</.h3>
          <ul>
            <%= for f <- @merge.files_changed do %>
              <li><pre><%= f %></pre></li>
            <% end %>
          </ul>
        </div>

        <div>
          <.h3>Raw Data</.h3>
          <pre>
            <%= Jason.encode!(@merge.raw, pretty: true) %>
          </pre>
        </div>
      </div>

    </div>
    """
  end

  def handle_event("merge", %{"merge" => params}, socket) do
    id = String.to_integer(params["id"])
    message = params["message"]

    Mrgr.Merge.merge!(id, message, socket.assigns.current_user)
    |> case do
      {:ok, _merge} ->
        socket
        |> put_flash(:info, "OK! 🥳")
        |> noreply()

      {:error, message} ->
        socket
        |> put_flash(:error, message)
        |> noreply()
    end
  end

  def external_merge_url(merge) do
    Mrgr.Schema.Merge.external_merge_url(merge)
  end
end
