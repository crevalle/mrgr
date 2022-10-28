defmodule Mrgr.Merge do
  use Mrgr.PubSub.Event

  require Logger

  import Mrgr.Tuple

  alias Mrgr.Merge.Query
  alias Mrgr.Schema.Merge, as: Schema

  ## release task
  def migrate_merge_status do
    Mrgr.Repo.all(Schema)
    |> Enum.map(fn m -> Mrgr.Repo.preload(m, :repository) end)
    |> Enum.map(&synchronize_most_stuff/1)
  end

  def migrate_node_ids do
    Mrgr.Repo.all(Schema)
    |> Enum.map(fn m ->
      case Map.get(m.raw, "node_id") do
        nil ->
          m.id

        node_id ->
          m
          |> Ecto.Changeset.change(%{node_id: node_id})
          |> Mrgr.Repo.update()

          :ok
      end
    end)
  end

  def create_from_webhook(payload) do
    params = payload_to_params(payload)

    %Schema{}
    |> Schema.create_changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, merge} ->
        merge
        |> preload_installation()
        |> ensure_repository_hydrated()
        |> hydrate_github_data()
        |> append_to_merge_queue()
        |> create_checklists()
        |> notify_file_alert_consumers()
        |> broadcast(@merge_created)
        |> ok()

      {:error, _cs} = err ->
        err
    end
  end

  @spec reopen(map()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def reopen(payload) do
    with {:ok, merge} <- find_from_payload(payload),
         cs <- Schema.create_changeset(merge, payload_to_params(payload)),
         {:ok, updated_merge} <- Mrgr.Repo.update(cs) do
      updated_merge
      |> preload_installation()
      |> hydrate_github_data()
      |> append_to_merge_queue()
      |> broadcast(@merge_reopened)
      |> ok()
    else
      {:error, :not_found} ->
        create_from_webhook(payload)

      {:error, _cs} = error ->
        error
    end
  end

  @spec edit(map()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def edit(payload) do
    with {:ok, merge} <- find_from_payload(payload),
         cs <- Schema.edit_changeset(merge, payload),
         {:ok, updated_merge} <- Mrgr.Repo.update(cs) do
      updated_merge
      |> preload_installation()
      |> broadcast(@merge_edited)
      |> ok()
    else
      {:error, :not_found} -> create_from_webhook(payload)
      error -> error
    end
  end

  @spec synchronize(map()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def synchronize(payload) do
    with {:ok, merge} <- find_from_payload(payload) do
      merge
      |> preload_installation()
      |> hydrate_github_data()
      |> broadcast(@merge_synchronized)
      |> ok()
    else
      {:error, :not_found} -> create_from_webhook(payload)
    end
  end

  @spec close(map()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def close(%{"pull_request" => params} = payload) do
    with {:ok, merge} <- find_from_payload(payload),
         cs <- Schema.close_changeset(merge, params),
         {:ok, updated_merge} <- Mrgr.Repo.update(cs) do
      updated_merge
      |> preload_installation()
      |> remove_from_merge_queue()
      |> broadcast(@merge_closed)
      |> ok()
    else
      {:error, :not_found} = error ->
        Logger.warn("found no local PR")
        error

      {:error, _cs} = error ->
        error
    end
  end

  @spec assign_user(Schema.t(), Mrgr.Github.User.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def assign_user(merge, gh_user) do
    case Mrgr.List.absent?(merge.assignees, gh_user) do
      true ->
        case set_assignees(merge, [gh_user | merge.assignees]) do
          {:ok, merge} ->
            # we want to unsnooze only if the user has been tagged,
            # but we don't have the concept of per-user snoozing so
            # we can't answer the question "have i been tagged?" because we don't
            # know who "i" is.  the app is currently built around a #single_user
            # using it.
            #
            # rather than build out per-user snoozing,
            # just blanket unsnooze whenever anyone is added to tags, which should
            # be infrequent enough not to mess with the benefit of being snoozed.
            {:ok, unsnooze(merge)}

          error ->
            error
        end

      false ->
        # no-op
        {:ok, merge}
    end
  end

  @spec unassign_user(Schema.t(), Mrgr.Github.User.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def unassign_user(merge, gh_user) do
    case Mrgr.List.present?(merge.assignees, gh_user) do
      true ->
        set_assignees(merge, Mrgr.List.remove(merge.assignees, gh_user))

      false ->
        {:ok, merge}
    end
  end

  defp set_assignees(merge, assignees) do
    merge
    |> Schema.change_assignees(assignees)
    |> Mrgr.Repo.update()
    |> case do
      {:ok, merge} ->
        merge
        |> broadcast(@merge_assignees_updated)
        |> ok()

      error ->
        error
    end
  end

  @spec add_reviewer(Schema.t(), Mrgr.Github.User.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def add_reviewer(merge, gh_user) do
    case Mrgr.List.absent?(merge.requested_reviewers, gh_user) do
      true ->
        case set_reviewers(merge, [gh_user | merge.requested_reviewers]) do
          {:ok, merge} ->
            # we want to unsnooze only if the user has been tagged,
            # but we don't have the concept of per-user snoozing so
            # we can't answer the question "have i been tagged?" because we don't
            # know who "i" is.  the app is currently built around a #single_user
            # using it.
            #
            # rather than build out per-user snoozing,
            # just blanket unsnooze whenever anyone is added to tags, which should
            # be infrequent enough not to mess with the benefit of being snoozed.
            {:ok, unsnooze(merge)}

          error ->
            error
        end

      false ->
        # no-op
        {:ok, merge}
    end
  end

  @spec remove_reviewer(Schema.t(), Mrgr.Github.User.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def remove_reviewer(merge, gh_user) do
    case Mrgr.List.present?(merge.assignees, gh_user) do
      true ->
        set_reviewers(merge, Mrgr.List.remove(merge.requested_reviewers, gh_user))

      false ->
        {:ok, merge}
    end
  end

  defp set_reviewers(merge, reviewers) do
    merge
    |> Schema.change_reviewers(reviewers)
    |> Mrgr.Repo.update()
    |> case do
      {:ok, merge} ->
        merge
        |> broadcast(@merge_reviewers_updated)
        |> ok()

      error ->
        error
    end
  end

  def tagged?(merge, user) do
    (merge.assignees ++ merge.requested_reviewers)
    |> Enum.any?(&Mrgr.Schema.User.is_github_user?(user, &1))
  end

  def sync_comments(merge) do
    merge
    |> fetch_issue_comments()
    |> Enum.each(fn c ->
      create_comment("issue_comment", merge, c["created_at"], c)
    end)

    merge
    |> fetch_pr_review_comments()
    |> Enum.each(fn c ->
      create_comment("pull_request_review_comment", merge, c["created_at"], c)
    end)
  end

  def fetch_pr_review_comments(merge) do
    Mrgr.Github.API.fetch_pr_review_comments(
      merge.repository.installation,
      merge.repository,
      merge.number
    )
  end

  def fetch_issue_comments(merge) do
    Mrgr.Github.API.fetch_issue_comments(
      merge.repository.installation,
      merge.repository,
      merge.number
    )
  end

  @spec add_pull_request_review_comment(String.t(), Mrgr.Github.Webhook.t()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def add_pull_request_review_comment(object, params) do
    with {:ok, merge} <- find_from_payload(params),
         {:ok, comment} <- create_comment(object, merge, params["comment"]["created_at"], params) do
      # !!! we broadcast the merge, not the comment,
      # and let consumers figure out how to reconcile their data,
      # probably by reloading.
      #
      # Later when we know how we want to use comment data that can maybe become
      # its own data stream.  for now it's easier to just reload the merge
      # on the one pending_merge screen that uses it
      merge = %{merge | comments: [comment | merge.comments]}

      merge
      |> preload_installation()
      |> broadcast(@merge_comment_created)
      |> ok()
    end
  end

  def add_issue_comment(object, params) do
    with {:ok, merge} <- find_from_payload(params["issue"]),
         {:ok, comment} <- create_comment(object, merge, params["comment"]["created_at"], params) do
      merge = %{merge | comments: [comment | merge.comments]}

      merge
      |> preload_installation()
      |> broadcast(@merge_comment_created)
      |> ok()
    end
  end

  defp create_comment(object, merge, posted_at, params) do
    attrs = %{
      object: object,
      merge_id: merge.id,
      posted_at: posted_at,
      raw: params
    }

    attrs
    |> Mrgr.Schema.Comment.create_changeset()
    |> Mrgr.Repo.insert()
  end

  @spec add_pr_review(Schema.t(), map()) :: {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def add_pr_review(merge, %{"state" => "commented"}) do
    ### WARNING!  Silently does nothing.
    #
    # Add a review comment will also create a PR review with a state of "commented".
    # This will double-count the event in our activity stream.  However, doing Add Review -> Comment
    # will also create a pr_review, but no review comment, so by skipping all pr_reviews with a
    # state of "commented" we will ignore those items.  I think that's okay because who really does that
    # and it's better than double-counting things.

    # We still preload the existing pr_reviews to keep parity with the workhorse function below.
    {:ok, Mrgr.Repo.preload(merge, :pr_reviews)}
  end

  def add_pr_review(merge, params) do
    merge = Mrgr.Repo.preload(merge, :pr_reviews)

    merge
    |> Ecto.build_assoc(:pr_reviews)
    |> Mrgr.Schema.PRReview.create_changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, review} ->
        reviews = [review | merge.pr_reviews]

        # broadcast update
        {:ok, %{merge | pr_reviews: reviews}}

      error ->
        error
    end
  end

  def notify_file_alert_consumers(merge) do
    merge
    |> Mrgr.FileChangeAlert.for_merge()
    |> Enum.filter(& &1.notify_user)
    |> send_file_alert(merge)
  end

  def send_file_alert([], merge), do: merge

  def send_file_alert(alerts, merge) do
    installation = Mrgr.Repo.preload(merge.repository.installation, :creator)
    recipient = installation.creator
    url = build_url_to(merge)

    file_alerts =
      Enum.map(alerts, fn alert ->
        filenames = Mrgr.FileChangeAlert.matching_filenames(alert, merge)

        %{
          filenames: filenames,
          badge_text: alert.badge_text
        }
      end)

    mail = Mrgr.Notifier.file_alert(recipient, merge.repository, file_alerts, url)
    Mrgr.Mailer.deliver(mail)

    merge
  end

  defp build_url_to(merge) do
    MrgrWeb.Router.Helpers.pending_merge_url(MrgrWeb.Endpoint, :show, merge.id)
  end

  def snooze(merge, until) do
    merge
    |> Schema.snooze_changeset(until)
    |> Mrgr.Repo.update!()
  end

  def unsnooze(merge) do
    merge
    |> Schema.snooze_changeset(nil)
    |> Mrgr.Repo.update!()
  end

  def snoozed?(%{snoozed_until: nil}), do: false

  def snoozed?(%{snoozed_until: until}) do
    Mrgr.DateTime.in_the_future?(until)
  end

  @spec find_from_payload(Mrgr.Github.Webhook.t() | map()) ::
          {:ok, Schema.t()} | {:error, :not_found}
  defp find_from_payload(%{"node_id" => node_id}) do
    case find_by_node_id(node_id) do
      nil -> {:error, :not_found}
      merge -> {:ok, merge}
    end
  end

  defp find_from_payload(%{"pull_request" => params}) do
    find_from_payload(params)
  end

  def ensure_repository_hydrated(merge) do
    definitely_hydrated = Mrgr.Repository.ensure_hydrated(merge.repository)

    %{merge | repository: definitely_hydrated}
  end

  @spec merge!(Schema.t() | integer(), String.t(), Mrgr.Schema.User.t()) ::
          {:ok, Schema.t()} | {:error, String.t()}
  def merge!(%Schema{} = merge, message, merger) do
    # this only makes the API call.  side effects to the %Merge{} are handled in the close callback
    args = generate_merge_args(merge, message, merger)

    Mrgr.Github.API.merge_pull_request(args.client, args.owner, args.repo, args.number, args.body)
    |> case do
      {:ok, %{"sha" => _sha}} ->
        {:ok, merge}

      {:error, %{result: %{"message" => str}}} ->
        {:error, str}
    end
  end

  def merge!(id, message, merger) do
    case load_merge_for_merging(id) do
      nil -> {:error, :not_found}
      merge -> merge!(merge, message, merger)
    end
  end

  def broadcast(merge, event) do
    topic = Mrgr.PubSub.Topic.installation(merge.repository.installation)

    Mrgr.PubSub.broadcast(merge, topic, event)
    merge
  end

  def hydrate_github_data(merge) do
    merge
    |> synchronize_most_stuff()
    |> synchronize_commits()
  end

  # most, but not all.  doesn't include commits.  have been drinking sake and
  # will do that later ✌️
  def synchronize_most_stuff(merge) do
    %{"node" => node} = Mrgr.Github.API.fetch_most_merge_data(merge)

    files_changed = Enum.map(node["files"]["nodes"], & &1["path"])

    translated = %{
      files_changed: files_changed,
      merge_state_status: node["mergeStateStatus"],
      mergeable: node["mergeable"],
      title: node["title"]
    }

    merge
    |> Schema.most_changeset(translated)
    |> Mrgr.Repo.update!()
  end

  def synchronize_commits(merge) do
    commits =
      merge
      |> fetch_commits()
      # they come in with first commit first, i want most recent first (head)
      |> Enum.reverse()

    merge
    |> Schema.commits_changeset(%{commits: commits})
    |> Mrgr.Repo.update!()
  end

  def fetch_commits(merge) do
    Mrgr.Github.API.commits(merge, merge.repository.installation)
  end

  def generate_merge_args(merge, message, merger) do
    installation = merge.repository.installation

    client = Mrgr.Github.Client.new(merger)
    owner = installation.account.login
    repo = merge.repository.name
    number = merge.number
    head_commit = Mrgr.Schema.Merge.head(merge)

    body = %{
      "commit_title" => merge.title,
      "commit_message" => message,
      "sha" => head_commit.sha,
      "merge_method" => "squash"
    }

    %{client: client, owner: owner, repo: repo, number: number, body: body}
  end

  def load_merge_for_merging(id) do
    Schema
    |> Query.by_id(id)
    |> Query.preload_for_merging()
    |> Mrgr.Repo.one()
  end

  def find_by_external_id(id) do
    Schema
    |> Query.by_external_id(id)
    |> Mrgr.Repo.one()
  end

  def find_by_node_id(id) do
    Schema
    |> Query.by_node_id(id)
    |> Query.preload_for_merging()
    |> Query.with_comments()
    |> Mrgr.Repo.one()
  end

  def find_for_activity_feed(external_id) do
    Schema
    |> Query.by_external_id(external_id)
    |> Query.with_file_alert_rules()
    |> Mrgr.Repo.one()
  end

  def find(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_file_alert_rules()
    |> Mrgr.Repo.one()
  end

  def find_with_everything(id) do
    Schema
    |> Query.by_id(id)
    |> Query.preload_for_merging()
    |> Query.with_comments()
    |> Mrgr.Repo.one()
  end

  def pending_merges(%Mrgr.Schema.Installation{id: id}) do
    pending_merges(id)
  end

  def pending_merges(%Mrgr.Schema.User{current_installation_id: id}) do
    pending_merges(id)
  end

  def pending_merges(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.open()
    |> Query.order_by_priority()
    |> Query.with_pending_preloads()
    |> Mrgr.Repo.all()
  end

  def for_installation(%Mrgr.Schema.Installation{id: installation_id}) do
    Schema
    |> Query.for_installation(installation_id)
    |> Mrgr.Repo.all()
  end

  def preload_for_pending_list(merge) do
    Schema
    |> Query.by_id(merge.id)
    |> Query.with_pending_preloads()
    |> Mrgr.Repo.one()
  end

  def delete_installation_merges(installation) do
    Schema
    |> Query.for_installation(installation.id)
    |> Mrgr.Repo.all()
    |> Enum.map(&Mrgr.Repo.delete/1)
  end

  defp payload_to_params(%{"pull_request" => params} = payload) do
    repo = Mrgr.Repository.find_by_node_id(payload["repository"]["node_id"])

    params
    |> Map.put("repository_id", repo.id)
    |> Map.put("author_id", author_id_from_payload(payload))
    |> Map.put("opened_at", params["created_at"])
    |> Map.put("raw", params)
  end

  defp author_id_from_payload(payload) do
    user_id = payload["pull_request"]["user"]["id"]

    case Mrgr.User.find_member(user_id) do
      %Mrgr.Schema.Member{id: id} -> id
      nil -> nil
    end
  end

  defp append_to_merge_queue(merge) do
    all_pending_merges = pending_merges(merge.repository.installation)

    other_merges = Enum.reject(all_pending_merges, fn m -> m.id == merge.id end)

    Mrgr.MergeQueue.set_next_merge_queue_index(merge, other_merges)
  end

  defp remove_from_merge_queue(merge) do
    all_pending_merges = pending_merges(merge.repository.installation)

    {_updated_list, updated_merge} = Mrgr.MergeQueue.remove(all_pending_merges, merge)

    updated_merge
  end

  defp preload_installation(merge) do
    Mrgr.Repo.preload(merge, repository: [:installation, :file_change_alerts])
  end

  def create_checklists(merge) do
    merge
    |> fetch_applicable_checklist_templates()
    |> Enum.map(&Mrgr.ChecklistTemplate.create_checklist(&1, merge))

    merge
  end

  defp fetch_applicable_checklist_templates(merge) do
    Mrgr.ChecklistTemplate.for_repository(merge.repository)
  end

  def calculate_approvals(merge) do
    case merge.repository.required_approving_review_count do
      0 ->
        "no approvals required for this repo"

      num ->
        "(#{approving_reviews(merge)}/#{num}) approvals"
    end
  end

  def approving_reviews(merge) do
    merge.pr_reviews
    |> Enum.filter(&(&1.state == "approved"))
    |> Enum.count()
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, installation_id) do
      from([q, repository: r] in with_repository(query),
        join: i in assoc(r, :installation),
        where: i.id == ^installation_id
      )
    end

    def with_author(query) do
      from(q in query,
        left_join: a in assoc(q, :author),
        preload: [author: a]
      )
    end

    def open(query) do
      from(q in query,
        where: q.status == "open"
      )
    end

    def order_by_priority(query) do
      from(q in query,
        order_by: [asc: q.merge_queue_index]
      )
    end

    def preload_for_merging(query) do
      from([q, repository: r] in with_repository(query),
        join: i in assoc(r, :installation),
        join: a in assoc(i, :account),
        preload: [repository: {r, [installation: {i, [account: a]}]}]
      )
    end

    def with_repository(query) do
      case has_named_binding?(query, :repository) do
        true ->
          query

        false ->
          from(q in query,
            join: r in assoc(q, :repository),
            as: :repository,
            preload: [repository: r]
          )
      end
    end

    def with_file_alert_rules(query) do
      from([q, repository: r] in with_repository(query),
        left_join: a in assoc(r, :file_change_alerts),
        preload: [repository: {r, [file_change_alerts: a]}]
      )
    end

    def with_checklist(query) do
      from(q in query,
        left_join: checklist in assoc(q, :checklist),
        left_join: checks in assoc(checklist, :checks),
        left_join: approval in assoc(checks, :check_approval),
        left_join: user in assoc(approval, :user),
        preload: [
          checklist: {checklist, [checks: {checks, [check_approval: {approval, [user: user]}]}]}
        ]
      )
    end

    def with_comments(query) do
      from(q in query,
        left_join: c in assoc(q, :comments),
        preload: [comments: c]
      )
    end

    def with_pr_reviews(query) do
      from(q in query,
        left_join: prr in assoc(q, :pr_reviews),
        preload: [pr_reviews: prr]
      )
    end

    def with_pending_preloads(query) do
      query
      |> with_file_alert_rules()
      |> with_checklist()
      |> with_comments()
      |> with_pr_reviews()
    end
  end
end
