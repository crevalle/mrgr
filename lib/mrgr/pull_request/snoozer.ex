defmodule Mrgr.PullRequest.Snoozer do
  # Snoozing is a join between users and pull requests.
  # A PR may be snoozed by multiple people, so we always need to
  # ask if it's snoozed *for a user*.  When we load a PR's snoozy
  # joins, we assume that there will be either one join record
  # (ie, for the user in question) or no join records if it's unsnoozed.
  #
  # Unsnoozed can also look like %Ecto.AssociationNotLoaded{} because
  # naively preloading the assoc will pull in snoozed joins from other users.
  # ==> Our current implementation does a NOT IN query of snoozed ids.
  # If that implementation changes we may have a different
  # understanding of the %Ecto.AssociationNotLoaded{} struct.
  #
  # Meanwhile, callers of snooze functions need to have some awareness of
  # what's going on under the hood.  PAY ATTENTION if you're expecting the
  # whole list of join records on a %PullRequest{}.

  use Mrgr.PubSub.Event

  alias __MODULE__.Query
  alias Mrgr.Schema.UserSnoozedPullRequest, as: Schema

  def snoozed_pr_ids_for_user(user) do
    Schema
    |> Query.for_user(user)
    |> Mrgr.Repo.all()
    |> Enum.map(& &1.pull_request_id)
  end

  # ask this question with caution.  see notes at top of file
  def snoozed?(%{user_snoozed_pull_requests: []}), do: false
  def snoozed?(%{user_snoozed_pull_requests: %Ecto.Association.NotLoaded{}}), do: false
  def snoozed?(_pull_request), do: true

  def snoozed_until(%{user_snoozed_pull_requests: [uspr | _rest]}) do
    uspr.snoozed_until
  end

  def snoozed_until(_), do: nil

  def snooze_for_user(pull_request, user, until) do
    params = %{
      pull_request_id: pull_request.id,
      user_id: user.id,
      snoozed_until: until
    }

    uspr =
      %Schema{}
      |> Schema.changeset(params)
      |> Mrgr.Repo.insert!()

    Mrgr.PullRequest.broadcast(pull_request, @pull_request_snoozed)

    %{pull_request | user_snoozed_pull_requests: [uspr]}
  end

  def unsnooze_for_user(pull_request, user) do
    snoozed = find_uspr(pull_request, user)

    Mrgr.Repo.delete(snoozed)

    Mrgr.PullRequest.broadcast(pull_request, @pull_request_unsnoozed)

    %{pull_request | user_snoozed_pull_requests: []}
  end

  def unsnooze(pull_request) do
    Schema
    |> Query.for_pull_request(pull_request)
    |> Mrgr.Repo.all()
    |> Enum.map(& &1.delete)

    Mrgr.PullRequest.broadcast(pull_request, @pull_request_unsnoozed)

    %{pull_request | user_snoozed_pull_requests: []}
  end

  # %UserSnoozedPullRequest{}
  def find_uspr(pull_request, user) do
    Schema
    |> Query.for_pull_request(pull_request)
    |> Query.for_user(user)
    |> Mrgr.Repo.one()
  end

  defmodule Query do
    use Mrgr.Query

    def for_user(query, user) do
      from(q in query,
        where: q.user_id == ^user.id
      )
    end

    def for_pull_request(query, pull_request) do
      from(q in query,
        where: q.pull_request_id == ^pull_request.id
      )
    end
  end
end
