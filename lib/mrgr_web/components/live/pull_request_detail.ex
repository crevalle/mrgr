defmodule MrgrWeb.Components.Live.PullRequestDetail do
  use MrgrWeb, :live_component
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.PullRequest

  def handle_event("merge", %{"pull_request" => params}, socket) do
    id = String.to_integer(params["id"])
    message = params["message"]

    Mrgr.PullRequest.merge!(id, message, socket.assigns.current_user)
    |> case do
      {:ok, _pull_request} ->
        socket
        |> noreply()

      {:error, message} ->
        socket
        |> Flash.put(:error, message)
        |> noreply()
    end
  end

  def external_pull_request_url(pull_request) do
    Mrgr.Schema.PullRequest.external_pull_request_url(pull_request)
  end
end
