defmodule Mrgr.Merge do
  alias Mrgr.Merge.Query

  @topic "merge"

  def topic, do: @topic

  def create_from_webhook(payload) do
    params = payload_to_params(payload)

    %Mrgr.Schema.Merge{}
    |> Mrgr.Schema.Merge.create_changeset(params)
    |> Mrgr.Repo.insert()
    |> maybe_broadcast("created")
  end

  def reopen(payload) do
    external_id = payload["pull_request"]["id"]

    case find_by_external_id(external_id) do
      %Mrgr.Schema.Merge{} = merge ->
        params = payload_to_params(payload)

        merge
        |> Mrgr.Schema.Merge.create_changeset(params)
        |> Mrgr.Repo.update()
        |> maybe_broadcast("reopened")

      nil ->
        create_from_webhook(payload)
    end
  end

  def synchronize(payload) do
    external_id = payload["pull_request"]["id"]
    merge = find_by_external_id(external_id)

    merge
    |> Mrgr.Schema.Merge.synchronize_changeset(payload)
    |> Mrgr.Repo.update()
    |> maybe_broadcast("synchronized")
  end

  @spec merge!(Mrgr.Schema.Merge.t(), Mrgr.Schema.User.t()) ::
          {:ok, Mrgr.Schema.Merge.t()} | {:error, String.t()}
  def merge!(%Mrgr.Schema.Merge{} = merge, merger) do
    args = generate_merge_args(merge, merger)

    Tentacat.Pulls.merge(args.client, args.owner, args.repo, args.number, args.body)
    |> handle_merge_response()
    |> case do
      {:ok, %{"sha" => _sha}} ->
        merge = mark_merged!(merge, merger)
        # TODO: pubsub
        {:ok, merge}

      {:error, %{result: %{"message" => message}}} ->
        {:error, message}
    end
  end

  def merge!(id, merger) do
    case load_merge_for_merging(id) do
      nil -> {:error, :not_found}
      merge -> merge!(merge, merger)
    end
  end

  def mark_merged!(merge, merger) do
    member = Mrgr.User.member(merger)

    merge
    |> Mrgr.Schema.Merge.merge_changeset(%{merged_by_id: member.id})
    |> Mrgr.Repo.update!()
  end

  def maybe_broadcast({:ok, merge}, event) do
    Mrgr.PubSub.broadcast(merge, topic(), event)
    {:ok, merge}
  end

  def maybe_broadcast({:error, _cs} = error), do: error

  def handle_merge_response({200, result, _response}) do
    {:ok, result}
  end

  def handle_merge_response({code, result, _response}) do
    {:error, %{code: code, result: result}}
  end

  def generate_merge_args(merge, merger) do
    installation = merge.repository.installation

    client = Mrgr.Github.Client.new(merger)
    owner = installation.account.login
    repo = merge.repository.name
    number = merge.number

    body = %{
      "commit_title" => "Merge Dat Shit",
      "commit_message" => "I have ants in my pants",
      "sha" => merge.head.sha
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

  def pending_merges(%{current_installation_id: id}) do
    Mrgr.Schema.Merge
    |> Query.for_installation(id)
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

  defp payload_to_params(payload) do
    repository_id = payload["repository"]["id"]
    repo = Mrgr.Github.find(Mrgr.Schema.Repository, repository_id)

    payload
    |> Map.get("pull_request")
    |> Map.put("repository_id", repo.id)
    |> Map.put("author_id", author_id_from_payload(payload))
    |> Map.put("opened_at", payload["pull_request"]["created_at"])
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

    # for now, opened_at
    def order_by_priority(query) do
      from(q in query,
        order_by: [desc: q.opened_at]
      )
    end

    def preload_for_merging(query) do
      from(q in query,
        join: r in assoc(q, :repository),
        join: i in assoc(r, :installation),
        join: a in assoc(i, :account),
        preload: [repository: {r, [installation: {i, [account: a]}]}]
        # preload: [current_installation: {c, account: a}]
      )
    end
  end
end
