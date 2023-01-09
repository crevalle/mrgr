defmodule MrgrWeb.Components.Live.ActionMenuComponent do
  use MrgrWeb, :live_component

  def handle_event("save", %{"poke" => params}, socket) do
    type = params["type"]
    message = params["message"]

    # let's just assume that this works :D
    Task.start(fn ->
      Mrgr.Poke.create(socket.assigns.pull_request, socket.assigns.current_user, type, message)
    end)

    socket
    |> noreply()
  end

  def members_sans_author(members, %{author: nil}), do: members

  def members_sans_author(members, pull_request) do
    Enum.reject(members, fn m -> m.login == pull_request.author.login end)
  end

  def default_author_poke_message(pull_request) do
    author = username(pull_request.author)

    case Mrgr.PullRequest.merge_action_state(pull_request) do
      :ready_to_merge -> "#{author} this PR is approved, can you please merge it?"
      :needs_approval -> "#{author} this PR needs approvals, can you poke your teammates?"
      :fix_ci -> "#{author} CI is broken, can you please fix it?"
      _ -> ""
    end
  end

  def default_reviewers_poke_message(pull_request) do
    reviewers = usernames(pull_request.requested_reviewers)

    "#{reviewers} will you please look at this PR?"
  end
end
