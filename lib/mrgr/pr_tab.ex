defmodule Mrgr.PRTab do
  alias Mrgr.Schema.PRTab, as: Schema
  alias __MODULE__.Query

  def for_user(user) do
    Schema
    |> Query.for_user(user)
    |> Query.cron()
    |> Mrgr.Repo.all()
  end

  def create(user) do
    %Schema{}
    |> Schema.changeset(%{user_id: user.id})
    |> Mrgr.Repo.insert!()
  end

  def delete(tab) do
    Mrgr.Repo.delete(tab)
  end

  defmodule Query do
    use Mrgr.Query

    def for_user(query, user) do
      from(q in query,
        where: q.user_id == ^user.id
      )
    end
  end
end
