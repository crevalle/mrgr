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

  @spec snoozed_pr_ids_for_user(Mrgr.Schema.User.t()) :: [integer()]
  def snoozed_pr_ids_for_user(user) do
    Schema
    |> Query.for_user(user)
    |> Mrgr.Repo.all()
    |> Enum.map(& &1.pull_request_id)
  end

  # ask this question with caution.  see notes at top of file
  @spec snoozed?(Mrgr.Schema.UserSnoozedPullRequest.t()) :: boolean()
  def snoozed?(%{user_snoozed_pull_requests: []}), do: false
  def snoozed?(%{user_snoozed_pull_requests: %Ecto.Association.NotLoaded{}}), do: false
  def snoozed?(_pull_request), do: true

  @spec snoozed_until(Mrgr.Schema.PullRequest.t()) :: DateTime.t() | nil
  def snoozed_until(%{user_snoozed_pull_requests: [uspr | _rest]}) do
    uspr.snoozed_until
  end

  def snoozed_until(_), do: nil

  @spec snooze_for_user(Mrgr.Schema.PullRequest.t(), Mrgr.Schema.User.t(), DateTime.t()) ::
          Mrgr.Schema.PullRequest.t()
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

  @spec unsnooze_for_user(Mrgr.Schema.PullRequest.t(), Mrgr.Schema.User.t() | nil) ::
          Mrgr.Schema.PullRequest.t()
  def unsnooze_for_user(pull_request, nil), do: pull_request

  def unsnooze_for_user(pull_request, user) do
    case find_uspr(pull_request, user) do
      nil ->
        pull_request

      snoozed ->
        Mrgr.Repo.delete(snoozed)

        # nb: this will broadcast to other people
        Mrgr.PullRequest.broadcast(pull_request, @pull_request_unsnoozed)

        %{pull_request | user_snoozed_pull_requests: []}
    end
  end

  @spec unsnooze(Mrgr.Schema.PullRequest.t()) :: Mrgr.Schema.PullRequest.t()
  def unsnooze(pull_request) do
    Schema
    |> Query.for_pull_request(pull_request)
    |> Mrgr.Repo.all()
    |> Enum.map(& &1.delete)

    Mrgr.PullRequest.broadcast(pull_request, @pull_request_unsnoozed)

    %{pull_request | user_snoozed_pull_requests: []}
  end

  @spec find_uspr(Mrgr.Schema.PullRequest.t(), Mrgr.Schema.User.t()) ::
          Mrgr.Schema.UserSnoozedPullRequest.t() | nil
  def find_uspr(pull_request, user) do
    Schema
    |> Query.for_pull_request(pull_request)
    |> Query.for_user(user)
    |> Mrgr.Repo.one()
  end

  @spec expire_past_due_snoozes() :: [Mrgr.Schema.UserSnoozedPullRequest.t()]
  def expire_past_due_snoozes do
    expired =
      Schema
      |> Query.expired_snoozes()
      |> Mrgr.Repo.all()

    Enum.map(expired, &Mrgr.Repo.delete/1)

    expired
    |> Enum.map(& &1.pull_request_id)
    |> Enum.uniq()
    |> Mrgr.PullRequest.find_by_ids_with_repository()
    |> Enum.map(&Mrgr.PullRequest.broadcast(&1, @pull_request_unsnoozed))

    expired
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

    def expired_snoozes(query) do
      now = Mrgr.DateTime.safe_truncate(Mrgr.DateTime.now())

      from(q in query,
        where: q.snoozed_until < ^now
      )
    end
  end
end
