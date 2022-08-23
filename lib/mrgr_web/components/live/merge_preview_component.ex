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
        <div class="flex flex-col">
          <div class="flex items-start items-center">
            <.h1><%= @merge.title %></.h1>
            <%= link to: external_merge_url(@merge), target: "_blank" do %>
              <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg"  fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            <% end %>
          </div>
          <div class="pt-1">
            <p>
              Opened by <%= @merge.user.login %>
            </p>
            <p>
              <%= ts(@merge.opened_at) %>
            </p>
            <p>
              <%= MrgrWeb.Component.PendingMerge.change_badges(%{merge: @merge}) %>
            </p>
          </div>
        </div>

        <div>
          <%= @merge.id %>
        </div>

        <.h3>Merge This Pull Request</.h3>

        <%= if merge_frozen?(@repos, @merge.repository) do %>
          <p class="text-blue-600 italic">A Merge Freeze is in effect for this repository. This PR cannot be merged.</p>
        <% end %>

        <.form let={f} for={:merge} phx-submit="merge" phx-target={@myself} class="flex flex-col space-y-4">
          <div class="mt-1">
            <.textarea form={f} field={:message} opts={[placeholder: "Commit message defaults to PR title.  Enter additional info here."]} />
          </div>
          <%= hidden_input f, :id, value: @merge.id %>
          <div class="flex items-end">
            <.button submit={true} phx_disable_with="Merging..." colors="bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-500">Merge!</.button>
          </div>
        </.form>

        <div>
          <.h3>Commits</.h3>
          <ul>
            <%= for c <- @merge.commits do %>
              <MrgrWeb.Component.PendingMerge.preview_commit commit={c} ./>
            <% end %>
          </ul>
        </div>

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
