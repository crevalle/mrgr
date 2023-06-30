defmodule MrgrWeb.Admin.Live.PullRequestShow do
  use MrgrWeb, :live_view

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    # !!! Will duplicate HIF badges because those are scoped per-user
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title={"PR #{@pull_request.title}"} />

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <MrgrWeb.Components.PullRequest.card
            pull_request={@pull_request}
            current_user={@current_user}
            timezone={@timezone}
          />
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      pull_request = Mrgr.PullRequest.find_with_everything(id)

      socket
      |> assign(:pull_request, pull_request)
      |> ok()
    else
      ok(socket)
    end
  end
end
