defmodule Mrgr.Merge do
  use Mrgr.PubSub.Event

  require Logger

  alias Mrgr.Merge.Query

  def create_from_webhook(payload) do
    params = payload_to_params(payload)

    %Mrgr.Schema.Merge{}
    |> Mrgr.Schema.Merge.create_changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, merge} ->
        merge
        |> preload_installation()
        |> synchronize_head()
        |> synchronize_commits()
        |> append_to_merge_queue()
        |> broadcast(@merge_created)

      {:error, _cs} = err ->
        err
    end
  end

  @spec reopen(map()) ::
          {:ok, Mrgr.Schema.Merge.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def reopen(payload) do
    with {:ok, merge} <- find_from_payload(payload),
         cs <- Mrgr.Schema.Merge.create_changeset(merge, payload_to_params(payload)),
         {:ok, updated_merge} <- Mrgr.Repo.update(cs) do
      updated_merge
      |> preload_installation()
      |> synchronize_head()
      |> synchronize_commits()
      |> append_to_merge_queue()
      |> broadcast(@merge_reopened)
    else
      {:error, :not_found} ->
        create_from_webhook(payload)

      {:error, _cs} = error ->
        error
    end
  end

  @spec synchronize(map()) ::
          {:ok, Mrge.Schema.Merge.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def synchronize(payload) do
    with {:ok, merge} <- find_from_payload(payload),
         cs <- Mrgr.Schema.Merge.synchronize_changeset(merge, payload),
         {:ok, updated_merge} <- Mrgr.Repo.update(cs) do
      updated_merge
      |> preload_installation()
      |> synchronize_head()
      |> synchronize_commits()
      |> broadcast(@merge_synchronized)
    end
  end

  @spec close(map()) ::
          {:ok, Mrge.Schema.Merge.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def close(%{"pull_request" => params} = payload) do
    with {:ok, merge} <- find_from_payload(payload),
         cs <- Mrgr.Schema.Merge.close_changeset(merge, params),
         {:ok, updated_merge} <- Mrgr.Repo.update(cs) do
      updated_merge
      |> preload_installation()
      |> synchronize_commits()
      |> remove_from_merge_queue()
      |> broadcast(@merge_closed)
    else
      {:error, :not_found} = error ->
        Logger.warn("found no local PR")
        error

      {:error, _cs} = error ->
        error
    end
  end

  defp find_from_payload(%{"pull_request" => %{"id" => id}}) do
    case find_by_external_id(id) do
      nil -> {:error, :not_found}
      merge -> {:ok, merge}
    end
  end

  @spec merge!(Mrgr.Schema.Merge.t() | integer(), String.t(), Mrgr.Schema.User.t()) ::
          {:ok, Mrgr.Schema.Merge.t()} | {:error, String.t()}
  def merge!(%Mrgr.Schema.Merge{} = merge, message, merger) do
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
    {:ok, merge}
  end

  def synchronize_head(merge) do
    files_changed = fetch_files_changed(merge, merge.repository.installation)
    head = fetch_head(merge, merge.repository.installation)

    merge
    |> Ecto.Changeset.change(%{files_changed: files_changed, head_commit: head})
    |> Mrgr.Repo.update!()
  end

  def synchronize_commits(merge) do
    commits =
      merge
      |> fetch_commits(merge.repository.installation)
      # they come in with first commit first, i want most recent first (head)
      |> Enum.reverse()

    merge
    |> Mrgr.Schema.Merge.commits_changeset(%{commits: commits})
    |> Mrgr.Repo.update!()
  end

  def fetch_commits(merge, auth) do
    Mrgr.Github.API.commits(merge, auth)
  end

  def fetch_head(merge, auth) do
    Mrgr.Github.API.head_commit(merge, auth)
  end

  def fetch_files_changed(merge, auth) do
    response = Mrgr.Github.API.files_changed(merge, auth)

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
    Mrgr.Schema.Merge
    |> Query.by_id(id)
    |> Query.preload_for_merging()
    |> Mrgr.Repo.one()
  end

  def find_by_external_id(id) do
    Mrgr.Schema.Merge
    |> Query.by_external_id(id)
    |> Mrgr.Repo.one()
  end

  def find_for_activity_feed(external_id) do
    Mrgr.Schema.Merge
    |> Query.by_external_id(external_id)
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
    Mrgr.Schema.Merge
    |> Query.for_installation(installation_id)
    |> Query.open()
    |> Query.order_by_priority()
    |> Query.with_file_alert_rules()
    |> Mrgr.Repo.all()
  end

  def merges(%Mrgr.Schema.Installation{id: installation_id}) do
    Mrgr.Schema.Merge
    |> Query.for_installation(installation_id)
    |> Query.order_by_priority()
    |> Query.with_file_alert_rules()
    |> Mrgr.Repo.all()
  end

  def preload_for_pending_list(merge) do
    Mrgr.Repo.preload(merge, repository: :file_change_alerts)
  end

  def delete_installation_merges(installation) do
    Mrgr.Schema.Merge
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
  end
end
