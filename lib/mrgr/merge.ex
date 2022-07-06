defmodule Mrgr.Merge do
  require Logger

  alias Mrgr.Merge.Query

  @topic "merge"

  def topic, do: @topic

  def create_from_webhook(payload) do
    params = payload_to_params(payload)

    %Mrgr.Schema.Merge{}
    |> Mrgr.Schema.Merge.create_changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, merge} ->
        merge
        |> store_files_changed()
        |> broadcast("created")

      {:error, cs} = err ->
        err
    end
  end

  @spec reopen(map()) ::
          {:ok, Mrgr.Schema.Merge.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def reopen(payload) do
    with {:ok, merge} <- find_from_payload(payload),
         cs <- Mrgr.Schema.Merge.create_changeset(payload_to_params(payload), merge),
         {:ok, updated_merge} <- Mrgr.Repo.update(cs) do
      broadcast(updated_merge, "reopened")
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
      |> store_files_changed()
      |> broadcast("synchronized")
    end
  end

  @spec close(map()) ::
          {:ok, Mrge.Schema.Merge.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def close(%{"pull_request" => params} = payload) do
    with {:ok, merge} <- find_from_payload(payload),
         cs <- Mrgr.Schema.Merge.close_changeset(merge, params),
         {:ok, updated_merge} <- Mrgr.Repo.update(cs) do
      broadcast(updated_merge, "closed")
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
    args = generate_merge_args(merge, message, merger)

    Tentacat.Pulls.merge(args.client, args.owner, args.repo, args.number, args.body)
    |> handle_merge_response()
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
    Mrgr.PubSub.broadcast(merge, topic(), event)
    {:ok, merge}
  end

  def handle_merge_response({200, result, _response}) do
    {:ok, result}
  end

  def handle_merge_response({code, result, _response}) do
    {:error, %{code: code, result: result}}
  end

  def store_files_changed(merge) do
    merge = Mrgr.Repo.preload(merge, repository: :installation)
    files_changed = fetch_files_changed(merge, merge.repository.installation)

    update_files_changed(merge, files_changed)
  end

  def fetch_files_changed(merge, auth) do
    response = Mrgr.Github.files_changed(merge, auth)

    # ["lib/mrgr/incoming_webhook.ex", "lib/mrgr/merge.ex",
    # "lib/mrgr/schema/merge.ex", "lib/mrgr/user.ex",
    # "lib/mrgr_web/admin/live/incoming_webhook.ex",
    # "lib/mrgr_web/admin/live/incoming_webhook_show.ex",
    # "lib/mrgr_web/live/pending_merge_live.ex", "lib/mrgr_web/router.ex",
    # "lib/mrgr_web/templates/layout/root.html.heex",
    # "priv/repo/migrations/20220703202923_create_merge_raw_data.exs"]

    Enum.map(response, fn c -> c["filename"] end)
  end

  def update_files_changed(merge, files) do
    merge
    |> Ecto.Changeset.change(%{files_changed: files})
    |> Mrgr.Repo.update!()
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
    |> Mrgr.Repo.all()
  end

  def preload_for_pending_list(merge) do
    Mrgr.Repo.preload(merge, [:repository])
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

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, installation_id) do
      from(q in query,
        join: r in assoc(q, :repository),
        join: i in assoc(r, :installation),
        where: i.id == ^installation_id,
        preload: [repository: r]
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
      from(q in query,
        join: r in assoc(q, :repository),
        join: i in assoc(r, :installation),
        join: a in assoc(i, :account),
        preload: [repository: {r, [installation: {i, [account: a]}]}]
      )
    end
  end
end
