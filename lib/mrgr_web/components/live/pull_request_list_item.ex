defmodule MrgrWeb.Components.Live.PullRequestListItem do
  use MrgrWeb, :live_component
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.PullRequest

  def update(assigns, socket) do
    changeset = build_changeset()

    socket
    |> assign(assigns)
    |> assign(:changeset, changeset)
    |> ok()
  end

  def handle_event("set-poke-message", %{"type" => type}, socket) do
    changeset =
      type
      |> to_message(socket.assigns.pull_request)
      |> build_changeset()

    socket
    |> assign(:changeset, changeset)
    |> noreply()
  end

  def handle_event("poke", %{"poke" => params}, socket) do
    message = params["message"]

    # let's just assume that this works :D
    Task.start(fn ->
      Mrgr.Poke.create(socket.assigns.pull_request, socket.assigns.current_user, message)
    end)

    socket
    |> assign(:changeset, build_changeset())
    |> noreply()
  end

  def build_changeset(message \\ nil) do
    %Mrgr.Schema.Poke{}
    |> Mrgr.Schema.Poke.changeset(%{message: message})
  end

  def to_message("author", pull_request) do
    author = username(pull_request.author)

    case Mrgr.PullRequest.merge_action_state(pull_request) do
      :ready_to_merge -> "#{author} this PR is approved, can you please merge it?"
      :needs_approval -> "#{author} this PR needs approvals, can you poke your teammates?"
      :fix_ci -> "#{author} CI is broken, can you please fix it?"
      _ -> ""
    end
  end

  def to_message("reviewers", pull_request) do
    reviewers = usernames(pull_request.requested_reviewers)

    "#{reviewers} will you please look at this PR?"
  end

  def to_message("good-job", _pull_request) do
    "nice work everyone! ✌️"
  end

  def repo_text_color(true), do: "text-blue-600"
  def repo_text_color(false), do: "text-gray-400"

  def item_border_color(item, selected) do
    case Mrgr.PullRequest.snoozed?(item) do
      true ->
        case selected do
          true -> "border-blue-500"
          false -> "border-blue-200"
        end

      false ->
        case selected do
          true -> "border-teal-500"
          false -> "border-gray-200"
        end
    end
  end
end
