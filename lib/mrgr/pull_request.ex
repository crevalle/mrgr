defmodule Mrgr.PullRequest do
  use Mrgr.PubSub.Event

  require Logger

  import Mrgr.Tuple

  alias Mrgr.PullRequest.Query
  alias Mrgr.Schema.PullRequest, as: Schema

  def load_authors do
    Schema
    |> Mrgr.Repo.all()
    |> Enum.map(&load_author/1)
  end

  def load_author(pull_request) do
    case Mrgr.Repo.get_by(Mrgr.Schema.Member, login: pull_request.user.login) do
      nil ->
        {:error, pull_request.id}

      member ->
        pull_request
        |> Ecto.Changeset.change(%{author_id: member.id})
        |> Mrgr.Repo.update()
    end
  end

  def create_from_webhook(payload) do
    params = payload_to_params(payload)

    %Schema{}
    |> Schema.create_changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, pull_request} ->
        pull_request
        |> preload_installation()
        |> sync_repo_if_first_pr()
        |> hydrate_github_data()
        |> create_checklists()
        |> notify_file_alert_consumers()
        |> broadcast(@pull_request_created)
        |> ok()

      {:error, _cs} = err ->
        err
    end
  end

  @spec reopen(map()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def reopen(payload) do
    with {:ok, pull_request} <- find_from_payload(payload),
         cs <- Schema.create_changeset(pull_request, payload_to_params(payload)),
         {:ok, updated_pull_request} <- Mrgr.Repo.update(cs) do
      updated_pull_request
      |> preload_installation()
      |> hydrate_github_data()
      |> broadcast(@pull_request_reopened)
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
    with {:ok, pull_request} <- find_from_payload(payload),
         cs <- Schema.edit_changeset(pull_request, payload),
         {:ok, updated_pull_request} <- Mrgr.Repo.update(cs) do
      updated_pull_request
      |> preload_installation()
      |> broadcast(@pull_request_edited)
      |> ok()
    else
      {:error, :not_found} -> create_from_webhook(payload)
      error -> error
    end
  end

  @spec synchronize(map()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def synchronize(payload) do
    with {:ok, pull_request} <- find_from_payload(payload) do
      pull_request
      |> preload_installation()
      |> hydrate_github_data()
      |> broadcast(@pull_request_synchronized)
      |> ok()
    else
      {:error, :not_found} -> create_from_webhook(payload)
    end
  end

  @spec close(map()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def close(%{"pull_request" => params} = payload) do
    with {:ok, pull_request} <- find_from_payload(payload),
         cs <- Schema.close_changeset(pull_request, params),
         {:ok, updated_pull_request} <- Mrgr.Repo.update(cs) do
      updated_pull_request
      |> preload_installation()
      |> broadcast(@pull_request_closed)
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
  def assign_user(pull_request, gh_user) do
    case Mrgr.List.absent?(pull_request.assignees, gh_user) do
      true ->
        case set_assignees(pull_request, [gh_user | pull_request.assignees]) do
          {:ok, pull_request} ->
            # we want to unsnooze only if the user has been tagged,
            # but we don't have the concept of per-user snoozing so
            # we can't answer the question "have i been tagged?" because we don't
            # know who "i" is.  the app is currently built around a #single_user
            # using it.
            #
            # rather than build out per-user snoozing,
            # just blanket unsnooze whenever anyone is added to tags, which should
            # be infrequent enough not to mess with the benefit of being snoozed.
            {:ok, unsnooze(pull_request)}

          error ->
            error
        end

      false ->
        # no-op
        {:ok, pull_request}
    end
  end

  @spec unassign_user(Schema.t(), Mrgr.Github.User.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def unassign_user(pull_request, gh_user) do
    case Mrgr.List.present?(pull_request.assignees, gh_user) do
      true ->
        set_assignees(pull_request, Mrgr.List.remove(pull_request.assignees, gh_user))

      false ->
        {:ok, pull_request}
    end
  end

  defp set_assignees(pull_request, assignees) do
    pull_request
    |> Schema.change_assignees(assignees)
    |> Mrgr.Repo.update()
    |> case do
      {:ok, pull_request} ->
        pull_request
        |> broadcast(@pull_request_assignees_updated)
        |> ok()

      error ->
        error
    end
  end

  @spec add_reviewer(Schema.t(), Mrgr.Github.User.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def add_reviewer(pull_request, gh_user) do
    case Mrgr.List.absent?(pull_request.requested_reviewers, gh_user) do
      true ->
        case set_reviewers(pull_request, [gh_user | pull_request.requested_reviewers]) do
          {:ok, pull_request} ->
            # we want to unsnooze only if the user has been tagged,
            # but we don't have the concept of per-user snoozing so
            # we can't answer the question "have i been tagged?" because we don't
            # know who "i" is.  the app is currently built around a #single_user
            # using it.
            #
            # rather than build out per-user snoozing,
            # just blanket unsnooze whenever anyone is added to tags, which should
            # be infrequent enough not to mess with the benefit of being snoozed.
            {:ok, unsnooze(pull_request)}

          error ->
            error
        end

      false ->
        # no-op
        {:ok, pull_request}
    end
  end

  @spec remove_reviewer(Schema.t(), Mrgr.Github.User.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def remove_reviewer(pull_request, gh_user) do
    case Mrgr.List.present?(pull_request.assignees, gh_user) do
      true ->
        set_reviewers(pull_request, Mrgr.List.remove(pull_request.requested_reviewers, gh_user))

      false ->
        {:ok, pull_request}
    end
  end

  defp set_reviewers(pull_request, reviewers) do
    pull_request
    |> Schema.change_reviewers(reviewers)
    |> Mrgr.Repo.update()
    |> case do
      {:ok, pull_request} ->
        pull_request
        |> broadcast(@pull_request_reviewers_updated)
        |> ok()

      error ->
        error
    end
  end

  def tagged?(pull_request, user) do
    (pull_request.assignees ++ pull_request.requested_reviewers)
    |> Enum.any?(&Mrgr.Schema.User.is_github_user?(user, &1))
  end

  def sync_comments(pull_request) do
    pull_request
    |> fetch_issue_comments()
    |> Enum.each(fn c ->
      create_comment("issue_comment", pull_request, c["created_at"], c)
    end)

    pull_request
    |> fetch_pr_review_comments()
    |> Enum.each(fn c ->
      create_comment("pull_request_review_comment", pull_request, c["created_at"], c)
    end)
  end

  def fetch_pr_review_comments(pull_request) do
    Mrgr.Github.API.fetch_pr_review_comments(
      pull_request.repository.installation,
      pull_request.repository,
      pull_request.number
    )
  end

  def fetch_issue_comments(pull_request) do
    Mrgr.Github.API.fetch_issue_comments(
      pull_request.repository.installation,
      pull_request.repository,
      pull_request.number
    )
  end

  @spec add_pull_request_review_comment(String.t(), Mrgr.Github.Webhook.t()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def add_pull_request_review_comment(object, params) do
    with {:ok, pull_request} <- find_from_payload(params),
         {:ok, comment} <-
           create_comment(object, pull_request, params["comment"]["created_at"], params) do
      # !!! we broadcast the pull_request, not the comment,
      # and let consumers figure out how to reconcile their data,
      # probably by reloading.
      #
      # Later when we know how we want to use comment data that can maybe become
      # its own data stream.  for now it's easier to just reload the pull_request
      # on the one pending_pull_request screen that uses it
      pull_request = %{pull_request | comments: [comment | pull_request.comments]}

      pull_request
      |> preload_installation()
      |> broadcast(@pull_request_comment_created)
      |> ok()
    end
  end

  def add_issue_comment(object, params) do
    with {:ok, pull_request} <- find_from_payload(params["issue"]),
         {:ok, comment} <-
           create_comment(object, pull_request, params["comment"]["created_at"], params) do
      pull_request = %{pull_request | comments: [comment | pull_request.comments]}

      pull_request
      |> preload_installation()
      |> broadcast(@pull_request_comment_created)
      |> ok()
    end
  end

  defp create_comment(object, pull_request, posted_at, params) do
    attrs = %{
      object: object,
      pull_request_id: pull_request.id,
      posted_at: posted_at,
      raw: params
    }

    attrs
    |> Mrgr.Schema.Comment.create_changeset()
    |> Mrgr.Repo.insert()
  end

  @spec add_pr_review(Schema.t(), map()) :: {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def add_pr_review(pull_request, %{"state" => "commented"}) do
    ### WARNING!  Silently does nothing.
    #
    # Add a review comment will also create a PR review with a state of "commented".
    # This will double-count the event in our activity stream.  However, doing Add Review -> Comment
    # will also create a pr_review, but no review comment, so by skipping all pr_reviews with a
    # state of "commented" we will ignore those items.  I think that's okay because who really does that
    # and it's better than double-counting things.

    # We still preload the existing pr_reviews to keep parity with the workhorse function below.
    {:ok, Mrgr.Repo.preload(pull_request, :pr_reviews)}
  end

  def add_pr_review(pull_request, params) do
    pull_request = Mrgr.Repo.preload(pull_request, :pr_reviews)

    pull_request
    |> Ecto.build_assoc(:pr_reviews)
    |> Mrgr.Schema.PRReview.create_changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, review} ->
        pull_request = %{pull_request | pr_reviews: [review | pull_request.pr_reviews]}

        pull_request
        # see if pull_request is unblocked
        |> synchronize_most_stuff()
        |> broadcast(@pull_request_reviews_updated)
        |> ok()

      error ->
        error
    end
  end

  def dismiss_pr_review(pull_request, review_node_id) do
    with %Mrgr.Schema.PRReview{} = review <-
           Mrgr.PRReview.find_for_pull_request(pull_request, review_node_id) do
      review
      |> Mrgr.Schema.PRReview.dismiss_changeset()
      |> Mrgr.Repo.update!()
    end

    pull_request
    |> Mrgr.Repo.preload(:pr_reviews, force: true)
    # see if pull_request is blocked
    |> synchronize_most_stuff()
    |> broadcast(@pull_request_reviews_updated)
    |> ok()
  end

  def notify_file_alert_consumers(pull_request) do
    pull_request
    |> Mrgr.FileChangeAlert.for_pull_request()
    |> Enum.filter(& &1.notify_user)
    |> send_file_alert(pull_request)
  end

  def send_file_alert([], pull_request), do: pull_request

  def send_file_alert(alerts, pull_request) do
    installation = Mrgr.Repo.preload(pull_request.repository.installation, :creator)
    recipient = installation.creator
    url = build_url_to(pull_request)

    file_alerts =
      Enum.map(alerts, fn alert ->
        filenames = Mrgr.FileChangeAlert.matching_filenames(alert, pull_request)

        %{
          filenames: filenames,
          name: alert.name
        }
      end)

    mail = Mrgr.Notifier.file_alert(recipient, pull_request.repository, file_alerts, url)
    Mrgr.Mailer.deliver(mail)

    pull_request
  end

  defp build_url_to(pull_request) do
    MrgrWeb.Router.Helpers.pull_request_url(MrgrWeb.Endpoint, :show, pull_request.id)
  end

  def snooze(pull_request, until) do
    pull_request
    |> Schema.snooze_changeset(until)
    |> Mrgr.Repo.update!()
  end

  def unsnooze(pull_request) do
    pull_request
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
      pull_request -> {:ok, pull_request}
    end
  end

  defp find_from_payload(%{"pull_request" => params}) do
    find_from_payload(params)
  end

  def sync_repo_if_first_pr(pull_request) do
    definitely_synced = Mrgr.Repository.sync_if_first_pr(pull_request.repository)

    %{pull_request | repository: definitely_synced}
  end

  @spec merge!(Schema.t() | integer(), String.t(), Mrgr.Schema.User.t()) ::
          {:ok, Schema.t()} | {:error, String.t()}
  def merge!(%Schema{} = pull_request, message, merger) do
    # this only makes the API call.  side effects to the %PullRequest{} are handled in the close callback
    args = generate_merge_args(pull_request, message, merger)

    Mrgr.Github.API.merge_pull_request(args.client, args.owner, args.repo, args.number, args.body)
    |> case do
      {:ok, %{"sha" => _sha}} ->
        {:ok, pull_request}

      {:error, %{result: %{"message" => str}}} ->
        {:error, str}
    end
  end

  def merge!(id, message, merger) do
    case load_pull_request_for_merging(id) do
      nil -> {:error, :not_found}
      pull_request -> merge!(pull_request, message, merger)
    end
  end

  def broadcast(pull_request, event) do
    topic = Mrgr.PubSub.Topic.installation(pull_request.repository)

    Mrgr.PubSub.broadcast(pull_request, topic, event)
    pull_request
  end

  def hydrate_github_data(pull_request) do
    pull_request
    |> synchronize_most_stuff()
    |> synchronize_commits()
  end

  def synchronize_most_stuff(pull_request) do
    %{"node" => node} = Mrgr.Github.API.fetch_most_pull_request_data(pull_request)

    files_changed = Enum.map(node["files"]["nodes"], & &1["path"])

    labels =
      node["labels"]["nodes"]
      |> Mrgr.Github.Label.from_graphql()
      |> Enum.map(&Mrgr.Github.Label.new/1)

    translated = %{
      files_changed: files_changed,
      merge_state_status: node["mergeStateStatus"],
      mergeable: node["mergeable"],
      title: node["title"]
    }

    pull_request
    |> update_labels_from_sync(labels)
    |> Schema.most_changeset(translated)
    |> Mrgr.Repo.update!()
  end

  def synchronize_commits(pull_request) do
    commits =
      pull_request
      |> fetch_commits()
      # they come in with first commit first, i want most recent first (head)
      |> Enum.reverse()

    pull_request
    |> Schema.commits_changeset(%{commits: commits})
    |> Mrgr.Repo.update!()
  end

  def fetch_commits(pull_request) do
    Mrgr.Github.API.commits(pull_request, pull_request.repository.installation)
  end

  def add_label(pull_request, %Mrgr.Github.Label{} = new_label) do
    case do_add_label(pull_request, new_label) do
      %Schema{} = pull_request ->
        pull_request
        |> Mrgr.Repo.preload(:labels)
        |> broadcast(@pull_request_labels_updated)

      :error ->
        :error
    end
  end

  def do_add_label(pull_request, %Mrgr.Github.Label{} = gh_label) do
    installation_id = pull_request.repository.installation_id

    with %Mrgr.Schema.Label{} = label <-
           Mrgr.Label.find_by_name_for_installation(gh_label.name, installation_id),
         nil <- find_pr_label(pull_request, label),
         {:ok, _pr_label} <- create_pr_label(pull_request, label) do
      pull_request
    else
      _ -> :error
    end
  end

  def find_pr_label(pull_request, %Mrgr.Github.Label{} = gh_label) do
    installation_id = pull_request.repository.installation_id

    with %Mrgr.Schema.Label{} = label <-
           Mrgr.Label.find_by_name_for_installation(gh_label.name, installation_id) do
      find_pr_label(pull_request, label)
    end
  end

  def find_pr_label(pull_request, %Mrgr.Schema.Label{} = label) do
    Mrgr.Repo.get_by(Mrgr.Schema.PullRequestLabel,
      pull_request_id: pull_request.id,
      label_id: label.id
    )
  end

  def create_pr_label(pull_request, label) do
    %Mrgr.Schema.PullRequestLabel{}
    |> Ecto.Changeset.change(%{pull_request_id: pull_request.id, label_id: label.id})
    |> Mrgr.Repo.insert()
  end

  def remove_label(pull_request, %Mrgr.Github.Label{} = gh_label) do
    case find_pr_label(pull_request, gh_label) do
      nil ->
        nil

      pr_label ->
        Mrgr.Repo.delete(pr_label)
    end

    pull_request
    |> Mrgr.Repo.preload(:labels)
    |> broadcast(@pull_request_labels_updated)
  end

  def update_labels_from_sync(pull_request, labels) do
    pull_request = Mrgr.Repo.preload(pull_request, :pr_labels)
    Enum.map(pull_request.pr_labels, &Mrgr.Repo.delete/1)

    Enum.map(labels, fn label -> do_add_label(pull_request, label) end)

    pull_request
    |> Mrgr.Repo.preload(:labels)
    |> broadcast(@pull_request_labels_updated)
  end

  def generate_merge_args(pull_request, message, merger) do
    installation = pull_request.repository.installation

    client = Mrgr.Github.Client.new(merger)
    owner = installation.account.login
    repo = pull_request.repository.name
    number = pull_request.number
    head_commit = Mrgr.Schema.PullRequest.head(pull_request)

    body = %{
      "commit_title" => pull_request.title,
      "commit_message" => message,
      "sha" => head_commit.sha,
      "merge_method" => "squash"
    }

    %{client: client, owner: owner, repo: repo, number: number, body: body}
  end

  def load_pull_request_for_merging(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_installation()
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
    |> Query.with_installation()
    |> Query.with_comments()
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
    |> Query.with_installation()
    |> Query.with_comments()
    |> Mrgr.Repo.one()
  end

  def open_pr_count(installation_id) do
    Schema
    |> Query.count_open(installation_id)
    |> Mrgr.Repo.one()
  end

  def paged_pending_pull_requests(user_or_id, opts \\ %{})

  def paged_pending_pull_requests(%{current_installation_id: id}, opts) do
    paged_pending_pull_requests(id, opts)
  end

  def paged_pending_pull_requests(installation_id, opts) do
    before = Map.get(opts, :before)
    since = Map.get(opts, :since)
    with_snoozed = Map.get(opts, :snoozed)

    # load in two passes because adding the joins messes up my LIMITs

    page =
      Schema
      |> Query.for_installation(installation_id)
      |> Query.open()
      |> Query.order_by_opened()
      |> Query.maybe_snooze(with_snoozed)
      |> Query.opened_between(before, since)
      |> Query.with_labels()
      |> Mrgr.Repo.paginate(opts)

    entries_with_preloads = Mrgr.Repo.preload(page.entries, Query.pending_preloads())
    %{page | entries: entries_with_preloads}
  end

  def paged_for_label(label, opts \\ %{}) do
    with_snoozed = Map.get(opts, :snoozed)

    page =
      Schema
      |> Query.open()
      |> Query.for_label(label)
      |> Query.order_by_opened()
      |> Query.maybe_snooze(with_snoozed)
      |> Mrgr.Repo.paginate(opts)

    entries_with_preloads = Mrgr.Repo.preload(page.entries, Query.pending_preloads())
    %{page | entries: entries_with_preloads}
  end

  def pending_pull_requests(%Mrgr.Schema.Installation{id: id}) do
    pending_pull_requests(id)
  end

  def pending_pull_requests(%Mrgr.Schema.User{current_installation_id: id}) do
    pending_pull_requests(id)
  end

  def pending_pull_requests(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.open()
    |> Query.order_by_opened()
    |> Query.with_pending_preloads()
    |> Mrgr.Repo.all()
  end

  def for_installation(%Mrgr.Schema.Installation{id: installation_id}) do
    Schema
    |> Query.for_installation(installation_id)
    |> Mrgr.Repo.all()
  end

  def open_for_repo_id(repository_id, page \\ []) do
    Schema
    |> Query.for_repository(repository_id)
    |> Query.open()
    |> Query.with_pending_preloads()
    |> Mrgr.Repo.paginate(page)
  end

  def preload_for_pending_list(pull_request) do
    Schema
    |> Query.by_id(pull_request.id)
    |> Query.with_pending_preloads()
    |> Mrgr.Repo.one()
  end

  def delete_installation_pull_requests(installation) do
    Schema
    |> Query.for_installation(installation.id)
    |> Mrgr.Repo.all()
    |> Enum.map(&Mrgr.Repo.delete/1)
  end

  defp payload_to_params(%{"pull_request" => params} = payload) do
    repo = Mrgr.Repository.find_by_node_id(payload["repository"]["node_id"])

    params
    |> Map.put("url", params["html_url"])
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

  defp preload_installation(pull_request) do
    Mrgr.Repo.preload(pull_request, repository: [:installation, :file_change_alerts])
  end

  def create_checklists(pull_request) do
    pull_request
    |> fetch_applicable_checklist_templates()
    |> Enum.map(&Mrgr.ChecklistTemplate.create_checklist(&1, pull_request))

    pull_request
  end

  defp fetch_applicable_checklist_templates(pull_request) do
    Mrgr.ChecklistTemplate.for_repository(pull_request.repository)
  end

  def fully_approved?(pull_request) do
    approving_reviews(pull_request) >= Schema.required_approvals(pull_request)
  end

  def approving_reviews(pull_request) do
    pull_request.pr_reviews
    |> Enum.filter(&(&1.state == "approved"))
    |> Enum.count()
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, installation_id) do
      from([q, repository: r] in with_repository(query),
        where: r.installation_id == ^installation_id
      )
    end

    def for_repository(query, id) do
      from(q in query,
        where: q.repository_id == ^id
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

    def maybe_snooze(query, :all), do: query

    def maybe_snooze(query, should_i) do
      if should_i do
        snoozed(query)
      else
        unsnoozed(query)
      end
    end

    def unsnoozed(query) do
      now = Mrgr.DateTime.safe_truncate(Mrgr.DateTime.now())

      from(q in query,
        where: is_nil(q.snoozed_until) or q.snoozed_until < ^now
      )
    end

    def snoozed(query) do
      now = Mrgr.DateTime.safe_truncate(Mrgr.DateTime.now())

      from(q in query,
        where: not is_nil(q.snoozed_until) and q.snoozed_until > ^now
      )
    end

    def with_installation(query) do
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

    def pending_preloads do
      [
        :comments,
        :pr_reviews,
        :author,
        repository: [:file_change_alerts]
      ]
    end

    def with_pending_preloads(query) do
      query
      |> with_file_alert_rules()
      |> with_comments()
      |> with_pr_reviews()
      |> with_labels()
      |> with_author()
    end

    def for_label(query, label) do
      from(q in query,
        join: l in assoc(q, :labels),
        where: l.id == ^label.id,
        preload: [labels: l]
      )
    end

    def with_labels(query) do
      from(q in query,
        left_join: l in assoc(q, :labels),
        preload: [labels: l]
      )
    end

    def order_by_opened(query) do
      from(q in query,
        order_by: [desc: q.opened_at]
      )
    end

    def opened_between(query, before, since) do
      query
      |> opened_before(before)
      |> opened_since(since)
    end

    def opened_before(query, nil), do: query

    def opened_before(query, before) do
      from(q in query, where: q.opened_at <= ^before)
    end

    def opened_since(query, nil), do: query

    def opened_since(query, since) do
      from(q in query, where: q.opened_at >= ^since)
    end

    def count_open(query, installation_id) do
      from(q in query,
        join: r in assoc(q, :repository),
        where: r.installation_id == ^installation_id,
        where: q.status == "open",
        select: count(q.id)
      )
    end
  end
end
