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

  def find_by_login(login) do
    Schema
    |> Query.by_login(login)
    |> Mrgr.Repo.one()
  end

  def find_from_github_user(%{login: login}), do: find_by_login(login)

  def delete_all_for_installation(installation) do
    memberships =
      Mrgr.Schema.Membership
      |> Query.where(installation_id: installation.id)
      |> Mrgr.Repo.all()

    member_ids = Enum.map(memberships, & &1.member_id)

    Enum.map(memberships, &Mrgr.Repo.delete/1)

    clear_orphaned_members(member_ids)
  end

  defp clear_orphaned_members(member_ids) do
    Schema
    |> Query.by_ids(member_ids)
    |> Query.with_memberships()
    |> Mrgr.Repo.all()
    |> Enum.filter(fn member -> Enum.empty?(member.memberships) end)
    |> Enum.map(&Mrgr.Repo.delete/1)
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

    def by_login(query, login) do
      from(q in query,
        where: q.login == ^login
      )
    end

    def with_memberships(query) do
      from(q in query,
        left_join: m in assoc(q, :memberships),
        preload: [memberships: m]
      )
    end
  end
end
