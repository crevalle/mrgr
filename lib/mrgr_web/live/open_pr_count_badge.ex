defmodule MrgrWeb.Live.OpenPRCountBadge do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      user = Mrgr.User.find_with_current_installation(user_id)
      subscribe_to_installation_switched(user.id)

      case user.current_installation do
        nil ->
          # onboarding, no current installation
          socket
          |> assign(:user, user)
          |> assign(:count, 0)
          |> ok()

        _installation ->
          subscribe(user)

          socket
          |> assign(:user, user)
          |> assign(:count, fetch_count(user))
          |> ok()
      end
    else
      ok(socket)
    end
  end

  def render(assigns) do
    ~H"""
    <.pr_count_badge count={@count} />
    """
  end

  def subscribe(user) do
    Mrgr.PubSub.subscribe_to_installation(user)
  end

  def subscribe_to_installation_switched(user_id) do
    Mrgr.PubSub.subscribe_to_user(user_id)
  end

  def handle_info(%{event: event}, socket)
      when event in [
             @pull_request_created,
             @pull_request_reopened,
             @pull_request_closed,
             @repository_visibility_updated
           ] do
    # can't just do naive increment/decrement because the PRs may be in hidden repos

    socket
    # TODO: re-enable after release task
    |> assign(:count, fetch_count(socket.assigns.user))
    |> noreply()
  end

  def handle_info(%{event: @installation_switched, payload: installation}, socket) do
    user = %{
      socket.assigns.user
      | current_installation_id: installation.id,
        current_installation: installation
    }

    socket
    |> assign(:user, user)
    |> assign(:count, fetch_count(user))
    |> noreply()
  end

  def handle_info(%{event: _who_cares}, socket) do
    noreply(socket)
  end

  def fetch_count(user) do
    Mrgr.PullRequest.open_pr_count(user)
  end
end
