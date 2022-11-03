defmodule MrgrWeb.Admin.Live.PullRequestList do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount MrgrWeb.Plug.Auth
  on_mount {MrgrWeb.Plug.Auth, :admin}

  def mount(%{"repository_id" => id}, _session, socket) do
    if connected?(socket) do
      repository = Mrgr.Repository.find(id)
      page = Mrgr.PullRequest.open_for_repo_id(id, page_size: 1)

      socket
      |> put_title("[Admin] #{repository.name}")
      |> assign(:repository, repository)
      |> assign(:page, page)
      |> assign(:pull_requests, page.entries)
      |> ok
    else
      {:ok, socket}
    end
  end

  def handle_event("nav", params, socket) do
    params =
      Map.put(params, "page_size", 1)
      |> IO.inspect()

    page =
      Mrgr.PullRequest.open_for_repo_id(socket.assigns.repository.id, params)
      |> IO.inspect()

    socket
    |> assign(:page, page)
    |> assign(:pull_requests, page.entries)
    |> noreply()
  end
end
