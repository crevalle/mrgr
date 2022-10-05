defmodule Mrgr.Merge do
  use Mrgr.PubSub.Event

  require Logger

  alias Mrgr.Merge.Query
  alias Mrgr.Schema.Merge, as: Schema

  ## release task
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
        |> hydrate_github_data()
        |> append_to_merge_queue()
        |> create_checklists()
        |> broadcast(@merge_created)
        |> Mrgr.Tuple.ok()

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
      |> Mrgr.Tuple.ok()
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
         cs <- Schema.synchronize_changeset(merge, payload),
         {:ok, updated_merge} <- Mrgr.Repo.update(cs) do
      updated_merge
      |> preload_installation()
      |> broadcast(@merge_edited)
      |> Mrgr.Tuple.ok()
    else
      {:error, :not_found} -> create_from_webhook(payload)
      error -> error
    end
  end

  @spec synchronize(map()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def synchronize(payload) do
    with {:ok, merge} <- find_from_payload(payload),
         cs <- Schema.synchronize_changeset(merge, payload),
         {:ok, updated_merge} <- Mrgr.Repo.update(cs) do
      updated_merge
      |> preload_installation()
      |> hydrate_github_data()
      |> broadcast(@merge_synchronized)
      |> Mrgr.Tuple.ok()
    else
      {:error, :not_found} -> create_from_webhook(payload)
      error -> error
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
      |> Mrgr.Tuple.ok()
    else
      {:error, :not_found} = error ->
        Logger.warn("found no local PR")
        error

      {:error, _cs} = error ->
        error
    end
  end

  @spec add_pull_request_review_comment(String.t(), Mrgr.Github.Webhook.t()) ::
          {:ok, Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def add_pull_request_review_comment(object, params) do
    with {:ok, merge} <- find_from_payload(params) do
      create_comment(object, merge, params)
    end
  end

  def add_issue_comment(object, params) do
    with {:ok, merge} <- find_from_payload(params["issue"]) do
      create_comment(object, merge, params)
    end
  end

  defp create_comment(object, merge, params) do
    attrs = %{
      object: object,
      raw: params,
      merge_id: merge.id
    }

    attrs
    |> Mrgr.Schema.Comment.create_changeset()
    |> Mrgr.Repo.insert()
  end

  @spec find_from_payload(Mrgr.Github.Webhook.t() | map()) ::
          {:ok, Schema.t()} | {:error, :not_found}
  defp find_from_payload(%{"pull_request" => params}) do
    find_from_payload(params)
  end

  defp find_from_payload(%{"node_id" => node_id}) do
    case find_by_node_id(node_id) do
      nil -> {:error, :not_found}
      merge -> {:ok, merge}
    end
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
    installation = merge.repository.installation

    hydrate_github_data(merge, installation)
  end

  def hydrate_github_data(merge, installation) do
    merge
    |> synchronize_head(installation)
    |> synchronize_commits(installation)
  end

  def synchronize_head(merge, installation) do
    files_changed = fetch_files_changed(merge, installation)
    head = fetch_head(merge, installation)

    merge
    |> Ecto.Changeset.change(%{files_changed: files_changed, head_commit: head})
    |> Mrgr.Repo.update!()
  end

  def synchronize_commits(merge, installation) do
    commits =
      merge
      |> fetch_commits(installation)
      # they come in with first commit first, i want most recent first (head)
      |> Enum.reverse()

    merge
    |> Schema.commits_changeset(%{commits: commits})
    |> Mrgr.Repo.update!()
  end

  def fetch_commits(merge, installation) do
    Mrgr.Github.API.commits(merge, installation)
  end

  def fetch_head(merge, installation) do
    Mrgr.Github.API.head_commit(merge, installation)
  end

  def fetch_files_changed(merge, installation) do
    response = Mrgr.Github.API.files_changed(merge, installation)

    # ["lib/mrgr/incoming_webhook.ex", "lib/mrgr/merge.ex",
    # "lib/mrgr/schema/merge.ex", "lib/mrgr/user.ex",
    # "lib/mrgr_web/admin/live/incoming_webhook.ex",
    # "lib/mrgr_web/admin/live/incoming_webhook_show.ex",
    # "lib/mrgr_web/live/pending_merge_live.ex", "lib/mrgr_web/router.ex",
    # "lib/mrgr_web/templates/layout/root.html.heex",
    # "priv/repo/migrations/20220703202923_create_merge_raw_data.exs"]

    Enum.map(response, fn c -> c["filename"] end)
  end

  def generate_merge_args(merge, message, merger) do
    installation = merge.repository.installation

    client = Mrgr.Github.Client.new(merger)
    owner = installation.account.login
    repo = merge.repository.name
    number = merge.number

    body = %{
      "commit_title" => merge.title,
      "commit_message" => message,
      "sha" => merge.head.sha,
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
    |> Query.with_file_alert_rules()
    |> Query.with_checklist()
    |> Mrgr.Repo.all()
  end

  def merges(%Mrgr.Schema.Installation{id: installation_id}) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order_by_priority()
    |> Query.with_file_alert_rules()
    |> Mrgr.Repo.all()
  end

  def preload_for_pending_list(merge) do
    Mrgr.Repo.preload(merge, repository: :file_change_alerts)
  end

  def delete_installation_merges(installation) do
    Schema
    |> Query.for_installation(installation.id)
    |> Mrgr.Repo.all()
    |> Enum.map(&Mrgr.Repo.delete/1)
  end

  defp payload_to_params(%{"pull_request" => params} = payload) do
    repository_id = payload["repository"]["id"]
    repo = Mrgr.Github.find(Mrgr.Schema.Repository, repository_id)

    params
    |> Map.put("repository_id", repo.id)
    |> Map.put("author_id", author_id_from_payload(payload))
    |> Map.put("opened_at", params["created_at"])
    |> Map.put("raw", params)
  end

  defp author_id_from_payload(payload) do
    user_id = payload["pull_request"]["user"]["id"]

    case Mrgr.Github.find(Mrgr.Schema.Member, user_id) do
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
  end
end
