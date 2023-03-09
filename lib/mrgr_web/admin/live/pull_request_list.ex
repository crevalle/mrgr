defmodule MrgrWeb.Admin.Live.PullRequestList do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def mount(%{"id" => installation_id}, _session, socket) do
    if connected?(socket) do
      pull_requests = Mrgr.PullRequest.admin_open_pull_requests(installation_id)

      members = Mrgr.Repo.all(Mrgr.Member.for_installation(installation_id))

      socket
      |> put_title("[Admin] Pull Requests")
      |> assign(:installation_id, installation_id)
      |> assign(:pull_requests, pull_requests)
      |> assign(:members, members)
      |> ok
    else
      {:ok, socket}
    end
  end
end
