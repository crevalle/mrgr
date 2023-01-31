defmodule MrgrWeb.Admin.Live.PullRequestList do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      page = Mrgr.PullRequest.paged_pending_pull_requests(id)

      members = Mrgr.Repo.all(Mrgr.Member.for_installation(id))

      socket
      |> put_title("[Admin] Pull Requests")
      |> assign(:installation_id, id)
      |> assign(:page, page)
      |> assign(:pull_requests, page.entries)
      |> assign(:members, members)
      |> ok
    else
      {:ok, socket}
    end
  end

  def handle_event("paginate", params, socket) do
    page = Mrgr.PullRequest.paged_pending_pull_requests(socket.assigns.installation_id, params)

    socket
    |> assign(:page, page)
    |> assign(:pull_requests, page.entries)
    |> noreply()
  end
end
