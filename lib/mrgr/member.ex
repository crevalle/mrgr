defmodule Mrgr.Member do
  alias Mrgr.Schema.Member, as: Schema
  alias __MODULE__.Query

  def paged_for_installation(installation_id, page \\ %{}) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order(desc: :login)
    |> Mrgr.Repo.paginate(page)
  end

  def for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order(desc: :login)
    |> Mrgr.Repo.all()
  end

  def tabs_for_user(user) do
    Schema
    |> Query.tabs_for_user(user.id)
    |> Mrgr.Repo.all()
  end

  def find_by_node_id(node_id) do
    Schema
    |> Query.by_node_id(node_id)
    |> Mrgr.Repo.one()
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, installation_id) do
      from(q in query,
        join: i in assoc(q, :installations),
        where: i.id == ^installation_id
      )
    end

    def tabs_for_user(query, user_id) do
      from(q in query,
        join: t in assoc(q, :pr_tab),
        where: t.user_id == ^user_id,
        preload: [pr_tab: t],
        order_by: [asc: t.inserted_at]
      )
    end
  end
end