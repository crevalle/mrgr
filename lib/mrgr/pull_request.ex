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
        |> sync_github_data()
        |> reassociate_high_impact_file_rules()
        |> notify_hif_alert_consumers()
        |> broadcast(@pull_request_created)
        |> ok()

      {:error, _cs} = err ->
        err
    end
  end

  def create_for_onboarding(data) do
    pull_request =
      %Schema{}
      |> Schema.create_changeset(data)
      |> Mrgr.Repo.insert!()

    # add the labels
    data["labels"]["nodes"]
    |> Mrgr.Github.Label.from_graphql()
    |> Enum.map(fn label -> do_add_label(pull_request, label, data["installation_id"]) end)

    # create the comments
    Enum.map(data["comments"]["nodes"], fn node ->
      create_comment("issue_comment", pull_request, node["publishedAt"], node)
    end)

    pull_request
  end

  @spec reopen(map()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def reopen(payload) do
    with {:ok, pull_request} <- find_from_payload(payload),
         cs <- Schema.create_changeset(pull_request, payload_to_params(payload)),
         {:ok, updated_pull_request} <- Mrgr.Repo.update(cs) do
      updated_pull_request
      |> preload_installation()
      |> sync_github_data()
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
      |> sync_github_data()
      |> reassociate_high_impact_file_rules()
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

  @spec toggle_reviewer(Schema.t(), Mrgr.Github.User.t() | Mrgr.Schema.Member.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def toggle_reviewer(pull_request, %Mrgr.Schema.Member{} = member) do
    toggle_reviewer(pull_request, Mrgr.Github.User.from_member(member))
  end

  def toggle_reviewer(pull_request, gh_user) do
    # for a smoother UX, we update locally and broadcast the update before
    # we push to GH, which we optimistically assume will work.  This lets me
    # avoid having to do a whole spinner thing on the UI.
    #
    # our add_reviewer and remove_reviewer webhooks are no-ops if the user has
    # already been added/removed.
    case Mrgr.Schema.PullRequest.reviewer_requested?(pull_request, gh_user) do
      true ->
        remove_reviewer(pull_request, gh_user)
        Mrgr.Github.API.remove_review_request(pull_request, gh_user.login)

      false ->
        add_reviewer(pull_request, gh_user)
        Mrgr.Github.API.add_review_request(pull_request, gh_user.login)
    end
  end

  @spec add_reviewer(Schema.t(), Mrgr.Github.User.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def add_reviewer(pull_request, gh_user) do
    case Mrgr.Schema.PullRequest.reviewer_requested?(pull_request, gh_user) do
      false ->
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

      true ->
        # no-op
        {:ok, pull_request}
    end
  end

  @spec remove_reviewer(Schema.t(), Mrgr.Github.User.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def remove_reviewer(pull_request, gh_user) do
    case Mrgr.Schema.PullRequest.reviewer_requested?(pull_request, gh_user) do
      true ->
        updated_list =
          Enum.reject(pull_request.requested_reviewers, fn r -> r.login == gh_user.login end)

        set_reviewers(pull_request, updated_list)

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

  @spec sync_comments(Schema.t()) :: Schema.t()
  def sync_comments(pull_request) do
    pull_request
    |> sync_issue_comments()
    |> sync_pr_review_comments()
  end

  def sync_issue_comments(pull_request) do
    pull_request
    |> fetch_issue_comments()
    |> Enum.each(fn c ->
      create_comment("issue_comment", pull_request, c["created_at"], c)
    end)

    pull_request
  end

  def sync_pr_review_comments(pull_request) do
    pull_request
    |> fetch_pr_review_comments()
    |> Enum.each(fn c ->
      create_comment("pull_request_review_comment", pull_request, c["created_at"], c)
    end)

    pull_request
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
        |> sync_github_data()
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
    |> sync_github_data()
    |> broadcast(@pull_request_reviews_updated)
    |> ok()
  end

  def reassociate_high_impact_file_rules(pull_request) do
    # until we get smarter about what's being added/removed for notification purposes,
    # just blow them all away and replace them

    Mrgr.HighImpactFileRule.reset(pull_request)
  end

  def notify_hif_alert_consumers(pull_request) do
    pull_request = Mrgr.Repo.preload(pull_request, :author)

    pull_request.high_impact_file_rules
    |> Enum.filter(& &1.notify_user)
    # don't send alerts to whomever opened the PR
    |> Enum.reject(&(&1.user_id == pull_request.author.user_id))
    |> Mrgr.HighImpactFileRule.send_alert(pull_request)

    pull_request
  end

  # see lib/mrgr/snoozer.ex for details on how snoozing works
  defdelegate snooze_for_user(pull_request, user, until), to: Mrgr.PullRequest.Snoozer
  defdelegate snoozed?(pull_request), to: Mrgr.PullRequest.Snoozer
  defdelegate snoozed_until(pull_request), to: Mrgr.PullRequest.Snoozer
  defdelegate unsnooze(pull_request), to: Mrgr.PullRequest.Snoozer
  defdelegate unsnooze_for_user(pull_request, user), to: Mrgr.PullRequest.Snoozer

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

  def broadcast(pull_request, event) do
    topic = Mrgr.PubSub.Topic.installation(pull_request.repository)

    Mrgr.PubSub.broadcast(pull_request, topic, event)
    pull_request
  end

  @spec create_rest_of_world(Schema.t()) :: Schema.t()
  def create_rest_of_world(pull_request) do
    pull_request
    |> synchronize_latest_ci_status!()
    |> sync_pr_review_comments()
  end

  def sync_github_data(pull_request) do
    %{"node" => node} = Mrgr.Github.API.fetch_light_pr_data(pull_request)

    translated = Mrgr.Github.PullRequest.GraphQL.to_params(node)

    labels = Mrgr.Github.Label.from_graphql(node["labels"]["nodes"])

    pull_request
    |> update_labels_from_sync(labels)
    |> Schema.most_changeset(translated)
    |> Mrgr.Repo.update!()
  end

  def synchronize_latest_ci_status!(pull_request) do
    case synchronize_latest_ci_status(pull_request) do
      {:ok, updated} -> updated
      _error -> pull_request
    end
  end

  @spec synchronize_latest_ci_status(Schema.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def synchronize_latest_ci_status(pull_request) do
    case fetch_check_suites_for_head(pull_request) do
      {:ok, result} ->
        status = ci_status_from_latest_check_suite_data(result)
        set_ci_status_conclusion(pull_request, status)

      error ->
        error
    end
  end

  def ci_status_from_latest_check_suite_data(%{"check_suites" => []}), do: "success"

  def ci_status_from_latest_check_suite_data(%{"check_suites" => suites}) do
    suites
    |> Enum.reverse()
    |> hd()
    |> case do
      %{"status" => "completed", "conclusion" => conclusion} -> conclusion
      %{"latest_check_runs_count" => 0} -> "success"
      _queued_or_running -> "running"
    end
  end

  def fetch_check_suites_for_head(pull_request) do
    case Mrgr.Github.API.check_suites_for_pr(pull_request) do
      %{"documentation_url" => _url, "message" => message} -> {:error, message}
      result -> {:ok, result}
    end
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

    do_add_label(pull_request, gh_label, installation_id)
  end

  def do_add_label(pull_request, gh_label, installation_id) do
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

  @spec set_ci_status_conclusion(Schema.t(), String.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def set_ci_status_conclusion(pull_request, status) when status in ["running", "success"] do
    with {:ok, pull_request} <- update_ci_status(pull_request, status) do
      pull_request
      |> broadcast(@pull_request_ci_status_updated)
      |> ok()
    end
  end

  def set_ci_status_conclusion(pull_request, _failure) do
    with {:ok, pull_request} <- update_ci_status(pull_request, "failure") do
      pull_request
      |> broadcast(@pull_request_ci_status_updated)
      |> ok()
    end
  end

  defp update_ci_status(pull_request, status) do
    pull_request
    |> Schema.ci_status_changeset(%{ci_status: status})
    |> Mrgr.Repo.update()
  end

  def find_by_external_id(id) do
    Schema
    |> Query.by_external_id(id)
    |> Mrgr.Repo.one()
  end

  def find_by_external_id_with_repository(id) do
    Schema
    |> Query.by_external_id(id)
    |> Query.with_repository()
    |> Mrgr.Repo.one()
  end

  def find_by_ids_with_repository(ids) when is_list(ids) do
    Schema
    |> Query.by_ids(ids)
    |> Query.with_repository()
    |> Mrgr.Repo.all()
  end

  def find_by_node_id(id) do
    Schema
    |> Query.by_node_id(id)
    |> Query.with_installation()
    |> Query.with_comments()
    |> Mrgr.Repo.one()
  end

  def find(id, preloads \\ []) do
    Schema
    |> Query.by_id(id)
    |> Mrgr.Repo.one()
    |> Mrgr.Repo.preload(preloads)
  end

  def find_with_everything(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_installation()
    |> Query.with_comments()
    |> Mrgr.Repo.one()
  end

  def open_pr_count(%Mrgr.Schema.User{} = user) do
    Schema
    |> Query.for_visible_repos(user.id)
    |> Query.for_installation(user.current_installation_id)
    |> Query.open()
    |> Query.unsnoozed(user)
    |> Mrgr.Repo.aggregate(:count)
  end

  def open_pr_count(installation_id) do
    Schema
    |> Query.count_open(installation_id)
    |> Mrgr.Repo.one()
  end

  def custom_tab_prs(tab) do
    Schema
    |> Query.dashboard_preloads(tab.user)
    |> Query.unsnoozed(tab.user)
    |> Query.for_custom_tab(tab)
    |> Mrgr.Repo.all()
  end

  def ready_to_merge_prs(user) do
    Schema
    |> Query.ready_to_merge()
    |> Query.dashboard_preloads(user)
    |> Query.unsnoozed(user)
    |> Mrgr.Repo.all()
  end

  def needs_approval_prs(user) do
    Schema
    |> Query.needs_approval()
    |> Query.dashboard_preloads(user)
    |> Query.unsnoozed(user)
    |> Mrgr.Repo.all()
  end

  def fix_ci_prs(user) do
    Schema
    |> Query.fix_ci()
    |> Query.dashboard_preloads(user)
    |> Query.unsnoozed(user)
    |> Mrgr.Repo.all()
  end

  def high_impact_prs(user) do
    ### unwrap all the pending stuff because we need to specify
    # that the HIF join is inner (ie, required)
    Schema
    |> Query.for_visible_repos(user.id)
    |> Query.for_installation(user.current_installation_id)
    |> Query.open()
    |> Query.order_by_opened()
    |> Query.high_impact(user)
    |> Query.with_comments()
    |> Query.with_pr_reviews()
    |> Query.with_labels()
    |> Query.with_author()
    |> Query.unsnoozed(user)
    |> Mrgr.Repo.all()
  end

  def snoozed_prs(user) do
    Schema
    |> Query.dashboard_preloads(user)
    |> Query.snoozed(user)
    |> Mrgr.Repo.all()
  end

  def admin_open_pull_requests(installation_id) do
    # returns snoozed and unsnoozed, but we can't tell which is which
    # based on this query
    Schema
    |> Query.for_installation(installation_id)
    |> Query.open()
    |> Query.order_by_opened()
    |> Query.with_hifs()
    |> Query.with_comments()
    |> Query.with_pr_reviews()
    |> Query.with_labels()
    |> Query.with_author()
    |> Mrgr.Repo.all()
  end

  def closed_this_week(user) do
    # "this week" is last seven days
    this_week = Mrgr.DateTime.shift_from_now(-7, :day)

    Schema
    |> Query.for_installation(user.current_installation_id)
    |> Query.merged()
    |> Query.merged_since(this_week)
    |> Query.with_author()
    |> Query.with_hifs_for_user(user)
    |> Mrgr.Repo.all()
  end

  def closed_last_week_count(installation_id) do
    # "this week" is last seven days
    this_week = Mrgr.DateTime.shift_from_now(-7, :day)
    last_week = Mrgr.DateTime.shift_from_now(-14, :day)

    Schema
    |> Query.for_installation(installation_id)
    |> Query.merged()
    |> Query.merged_since(last_week)
    |> Query.merged_before(this_week)
    |> Mrgr.Repo.aggregate(:count)
  end

  def closed_summary(installation_id, since) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.merged()
    |> Query.merged_since(since)
    |> Query.select([:id, :opened_at, :merged_at])
    |> Mrgr.Repo.all()
  end

  def closed_between(user, starting_date, ending_date) do
    Schema
    |> Query.for_installation(user.current_installation_id)
    |> Query.merged()
    |> Query.merged_since(starting_date)
    |> Query.merged_before(ending_date)
    |> Query.with_hifs_for_user(user)
    |> Mrgr.Repo.all()
  end

  def open_for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.open()
  end

  def for_installation(%Mrgr.Schema.Installation{id: installation_id}) do
    Schema
    |> Query.for_installation(installation_id)
    |> Mrgr.Repo.all()
  end

  def open_for_repo_id(repository_id) do
    Schema
    |> Query.for_repository(repository_id)
    |> Query.open()
    |> Query.with_repository()
    |> Query.with_hifs()
  end

  def preload_for_dashboard(pull_request, user) do
    Schema
    |> Query.by_id(pull_request.id)
    |> Query.dashboard_preloads(user)
    |> Mrgr.Repo.one()
  end

  def add_pending_preloads(page) do
    entries_with_preloads = Mrgr.Repo.preload(page.entries, Query.pending_preloads())
    %{page | entries: entries_with_preloads}
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
    |> Map.put("commits", [])
    |> Map.put("raw", params)
  end

  defp author_id_from_payload(payload) do
    user_id = payload["pull_request"]["user"]["id"]

    case Mrgr.User.find_member(user_id) do
      %Mrgr.Schema.Member{id: id} -> id
      nil -> nil
    end
  end

  def action_state(pull_request) do
    cond do
      ready_to_merge?(pull_request) -> :ready_to_merge
      needs_approval?(pull_request) -> :needs_approval
      needs_ci_fixed?(pull_request) -> :fix_ci
      true -> :ready_to_merge
    end
  end

  def ready_to_merge?(pull_request) do
    approved?(pull_request) && !ci_failed?(pull_request)
  end

  def needs_approval?(pull_request) do
    !approved?(pull_request) && !ci_failed?(pull_request)
  end

  def needs_ci_fixed?(pull_request) do
    ci_failed?(pull_request)
  end

  def approved?(%{
        approving_review_count: c,
        repository: %{settings: %{required_approving_review_count: r}}
      })
      when c >= r,
      do: true

  def approved?(_pull_request), do: false

  def ci_failed?(%{ci_status: "failure"}), do: true
  def ci_failed?(_pull_request), do: false

  defp preload_installation(pull_request) do
    Mrgr.Repo.preload(pull_request, repository: [:installation, :high_impact_file_rules])
  end

  def fully_approved?(pull_request) do
    pull_request.approving_review_count >= Schema.required_approvals(pull_request)
  end

  def time_open(%{merged_at: nil}), do: nil

  def time_open(pr) do
    DateTime.diff(pr.merged_at, pr.opened_at, :hour)
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, installation_id) do
      from([q, repository: r] in with_repository(query),
        where: r.installation_id == ^installation_id
      )
    end

    def for_visible_repos(query, user_id) do
      from([q, repository: r] in with_repository(query),
        join: uvr in assoc(r, :user_visible_repositories),
        where: uvr.user_id == ^user_id
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

    def for_custom_tab(query, tab) do
      query
      |> filter_draft_status(tab.draft_status)
      |> filter_authors(tab.authors)
      |> filter_labels(tab.labels)
      |> filter_repositories(tab.repositories)
    end

    def filter_draft_status(query, "both"), do: query

    def filter_draft_status(query, "draft") do
      from(q in query,
        where: q.draft == true
      )
    end

    def filter_draft_status(query, "open") do
      from(q in query,
        where: q.draft == false
      )
    end

    def filter_authors(query, []), do: query

    def filter_authors(query, authors) do
      author_ids = Enum.map(authors, & &1.id)

      from(q in query,
        where: q.author_id in ^author_ids
      )
    end

    def filter_labels(query, []), do: query

    def filter_labels(query, labels) do
      label_ids = Enum.map(labels, & &1.id)

      from(q in query,
        left_join: l in assoc(q, :labels),
        where: l.id in ^label_ids
      )
    end

    def filter_repositories(query, []), do: query

    def filter_repositories(query, repositories) do
      repository_ids = Enum.map(repositories, & &1.id)

      from(q in query,
        where: q.repository_id in ^repository_ids
      )
    end

    def unsnoozed(query, user) do
      snoozed_pr_ids = Mrgr.PullRequest.Snoozer.snoozed_pr_ids_for_user(user)

      from(q in query,
        where: q.id not in ^snoozed_pr_ids
      )
    end

    def snoozed(query, user) do
      from(q in query,
        join: uspr in assoc(q, :user_snoozed_pull_requests),
        where: uspr.user_id == ^user.id,
        preload: [user_snoozed_pull_requests: uspr]
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

    def with_hifs(query) do
      from(q in query,
        left_join: h in assoc(q, :high_impact_file_rules),
        preload: [high_impact_file_rules: h]
      )
    end

    def with_hifs_for_user(query, user) do
      sq = scoped_hifs_for_user(user)

      from(q in query,
        left_join: h in assoc(q, :high_impact_file_rules),
        left_lateral_join: for_pr in ^sq,
        on: for_pr.id == h.id,
        preload: [high_impact_file_rules: ^Ecto.Queryable.to_query(sq)]
      )
    end

    def high_impact(query, user) do
      sq = scoped_hifs_for_user(user)

      from(q in query,
        join: h in assoc(q, :high_impact_file_rules),
        inner_lateral_join: for_pr in ^sq,
        on: for_pr.id == h.id,
        preload: [high_impact_file_rules: ^Ecto.Queryable.to_query(sq)]
      )
    end

    def scoped_hifs_for_user(user) do
      subquery(
        from(q in Mrgr.Schema.HighImpactFileRule,
          where: q.user_id == ^user.id
        )
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
        :repository,
        :comments,
        :labels,
        :pr_reviews,
        :author,
        :high_impact_file_rules
      ]
    end

    def for_label(query, label) do
      from(q in query,
        join: l in assoc(q, :labels),
        where: l.id == ^label.id
      )
    end

    def for_author(query, author) do
      from(q in query,
        join: a in assoc(q, :author),
        where: a.id == ^author.id,
        preload: [author: a]
      )
    end

    def with_labels(query) do
      from(q in query,
        left_join: l in assoc(q, :labels),
        preload: [labels: l]
      )
    end

    def dashboard_preloads(query, user) do
      ### IF YOU ADD SOMETHING HERE MAKE SURE THE HIF TAB
      ### GETS IT TOO
      query
      |> for_visible_repos(user.id)
      |> for_installation(user.current_installation_id)
      |> open()
      |> order_by_opened()
      ### these are left-joined, the HIF tab is inner-joined
      |> with_hifs_for_user(user)
      |> with_comments()
      |> with_pr_reviews()
      |> with_labels()
      |> with_author()
    end

    def fix_ci(query) do
      query
      |> ci_failing()
    end

    def needs_approval(query) do
      query
      |> ci_passing_or_running()
      |> not_approved()
    end

    def ready_to_merge(query) do
      query
      |> ci_passing_or_running()
      |> approved()
    end

    def ci_passing_or_running(query) do
      from(q in query,
        where: q.ci_status == "running" or q.ci_status == "success"
      )
    end

    def ci_failing(query) do
      from(q in query,
        where: q.ci_status == "failure"
      )
    end

    def approved(query) do
      from([q, repository: r] in with_repository(query),
        where:
          q.approving_review_count >=
            fragment("(?->?)::integer", r.settings, "required_approving_review_count")
      )
    end

    def not_approved(query) do
      from([q, repository: r] in with_repository(query),
        where:
          q.approving_review_count <
            fragment("(?->?)::integer", r.settings, "required_approving_review_count")
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

    def merged(query) do
      from(q in query, where: not is_nil(q.merged_at))
    end

    def merged_since(query, since) do
      from(q in query, where: q.merged_at >= ^since)
    end

    def merged_before(query, before) do
      from(q in query, where: q.merged_at <= ^before)
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
