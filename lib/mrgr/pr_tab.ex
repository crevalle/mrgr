defmodule Mrgr.PRTab do
  alias Mrgr.Schema.PRTab, as: Schema
  alias __MODULE__.Query

  def rt_fill_permalinks do
    Schema
    |> Mrgr.Repo.all()
    |> Enum.map(fn tab ->
      case tab.title do
        nil ->
          tab
          |> Schema.edit_changeset(%{title: Schema.generate_random_tab_name()})
          |> Mrgr.Repo.update()

        _title ->
          tab
          |> Ecto.Changeset.change(%{permalink: Schema.generate_permalink(tab.title)})
          |> Mrgr.Repo.update()
      end
    end)
  end

  def for_user(user) do
    Schema
    |> Query.for_user(user)
    |> Query.with_authors()
    |> Query.with_labels()
    |> Query.with_repositories()
    |> Query.cron()
    |> Mrgr.Repo.all()
  end

  def create(user) do
    %Schema{}
    |> Schema.changeset(%{user_id: user.id})
    |> Mrgr.Repo.insert!()
    |> Mrgr.Repo.preload([:authors, :labels, :repositories, :user])
  end

  def update(tab, params) do
    tab
    |> Schema.edit_changeset(params)
    |> Mrgr.Repo.update()
  end

  def delete(tab) do
    Mrgr.Repo.delete(tab)
  end

  def toggle_author(tab, member) do
    tab
    |> author_present?(member)
    |> case do
      true ->
        remove_author(tab, member)

      false ->
        add_author(tab, member)
    end
  end

  def add_author(tab, member) do
    params = %{pr_tab_id: tab.id, author_id: member.id}

    %Mrgr.Schema.AuthorPRTab{}
    |> Ecto.Changeset.change(params)
    |> Mrgr.Repo.insert!()

    Mrgr.Repo.preload(tab, :authors, force: true)
  end

  def remove_author(tab, member) do
    Mrgr.Schema.AuthorPRTab
    |> Mrgr.Repo.get_by(pr_tab_id: tab.id, author_id: member.id)
    |> Mrgr.Repo.delete()

    Mrgr.Repo.preload(tab, :authors, force: true)
  end

  def author_present?(%{authors: authors}, member) do
    authors
    |> Enum.map(& &1.id)
    |> Enum.member?(member.id)
  end

  def toggle_label(tab, label) do
    tab
    |> label_present?(label)
    |> case do
      true ->
        remove_label(tab, label)

      false ->
        add_label(tab, label)
    end
  end

  def add_label(tab, label) do
    params = %{pr_tab_id: tab.id, label_id: label.id}

    %Mrgr.Schema.LabelPRTab{}
    |> Ecto.Changeset.change(params)
    |> Mrgr.Repo.insert!()

    Mrgr.Repo.preload(tab, :labels, force: true)
  end

  def remove_label(tab, label) do
    Mrgr.Schema.LabelPRTab
    |> Mrgr.Repo.get_by(pr_tab_id: tab.id, label_id: label.id)
    |> Mrgr.Repo.delete()

    Mrgr.Repo.preload(tab, :labels, force: true)
  end

  def label_present?(%{labels: labels}, label) do
    labels
    |> Enum.map(& &1.id)
    |> Enum.member?(label.id)
  end

  def toggle_repository(tab, repository) do
    tab
    |> repository_present?(repository)
    |> case do
      true ->
        remove_repository(tab, repository)

      false ->
        add_repository(tab, repository)
    end
  end

  def add_repository(tab, repository) do
    params = %{pr_tab_id: tab.id, repository_id: repository.id}

    %Mrgr.Schema.RepositoryPRTab{}
    |> Ecto.Changeset.change(params)
    |> Mrgr.Repo.insert!()

    Mrgr.Repo.preload(tab, :repositories, force: true)
  end

  def remove_repository(tab, repository) do
    Mrgr.Schema.RepositoryPRTab
    |> Mrgr.Repo.get_by(pr_tab_id: tab.id, repository_id: repository.id)
    |> Mrgr.Repo.delete()

    Mrgr.Repo.preload(tab, :repositories, force: true)
  end

  def repository_present?(%{repositories: repositories}, repository) do
    repositories
    |> Enum.map(& &1.id)
    |> Enum.member?(repository.id)
  end

  defmodule Query do
    use Mrgr.Query

    def for_user(query, user) do
      from(q in query,
        where: q.user_id == ^user.id,
        join: u in assoc(q, :user),
        preload: [user: u]
      )
    end

    def with_authors(query) do
      from(q in query,
        left_join: a in assoc(q, :authors),
        preload: [authors: a]
      )
    end

    def with_labels(query) do
      from(q in query,
        left_join: l in assoc(q, :labels),
        preload: [labels: l]
      )
    end

    def with_repositories(query) do
      from(q in query,
        left_join: r in assoc(q, :repositories),
        preload: [repositories: r]
      )
    end
  end
end
