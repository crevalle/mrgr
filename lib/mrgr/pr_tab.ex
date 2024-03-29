defmodule Mrgr.PRTab do
  alias Mrgr.Schema.PRTab, as: Schema
  alias __MODULE__.Query

  @drafty_statuses ["draft", "both"]
  @ready_statuses ["draft", "both"]

  def create_defaults_for_new_installation(%Mrgr.Schema.Installation{} = installation) do
    case Mrgr.Member.find_by_user_id(installation.creator_id) do
      %Mrgr.Schema.Member{} = member ->
        create_default_tabs(installation.creator_id, installation.id, member)

      nil ->
        []
    end
  end

  def create_default_tabs(user_id, installation_id, member) do
    params = %{
      user_id: user_id,
      installation_id: installation_id
    }

    my_prs =
      params
      |> Map.put(:title, "My PRs")
      |> create()
      |> add_author(member)

    assigned_to_me =
      params
      |> Map.put(:title, "Assigned to Me")
      |> create()
      |> add_reviewer(member)

    [my_prs, assigned_to_me]
  end

  def for_user(user) do
    # !!! pulls for the user's current installation
    # since that's almost always what we want
    Schema
    |> Query.for_user(user)
    |> Query.with_settings()
    |> Query.cron()
    |> Mrgr.Repo.all()
  end

  def matching_pull_request(pull_request) do
    Schema
    |> Query.for_installation(pull_request.repository.installation_id)
    |> Query.with_user()
    |> Query.with_settings()
    |> Mrgr.Repo.all()
    |> Enum.filter(fn tab -> matches_pr?(tab, pull_request) end)
  end

  def matches_pr?(tab, pr) do
    # only one needs to work
    with false <- matches_author?(tab, pr),
         false <- matches_reviewers?(tab, pr),
         false <- matches_labels?(tab, pr),
         false <- matches_repositories?(tab, pr),
         false <- matches_draft_status?(tab, pr) do
      false
    end
  end

  def matches_author?(tab, pr) do
    tab.authors
    |> Enum.map(& &1.node_id)
    |> Enum.member?(pr.author.node_id)
  end

  def matches_reviewers?(tab, pr) do
    tab_reviewer_ids = Enum.map(tab.reviewers, & &1.node_id)
    pr_reviewer_ids = Enum.map(pr.solicited_reviewers, & &1.node_id)

    Mrgr.List.intersection?(tab_reviewer_ids, pr_reviewer_ids)
  end

  def matches_labels?(tab, pr) do
    tab_label_ids = Enum.map(tab.labels, & &1.id)
    pr_label_ids = Enum.map(pr.labels, & &1.id)

    Mrgr.List.intersection?(tab_label_ids, pr_label_ids)
  end

  def matches_repositories?(tab, pr) do
    tab_repository_ids = Enum.map(tab.repositories, & &1.id)

    Enum.member?(tab_repository_ids, pr.repository_id)
  end

  def matches_draft_status?(%{draft_status: status}, %{draft: true})
      when status in @drafty_statuses,
      do: true

  def matches_draft_status?(%{draft_status: status}, %{draft: false})
      when status in @ready_statuses,
      do: true

  def matches_draft_status?(_tab, _pr), do: false

  def create_for_user(user) do
    params = %{user_id: user.id, installation_id: user.current_installation_id}

    create(params)
  end

  def create(params) do
    %Schema{}
    |> Schema.changeset(params)
    |> Mrgr.Repo.insert!()
    |> Mrgr.Repo.preload([:authors, :reviewers, :labels, :repositories, :user])
  end

  def update(tab, params) do
    tab
    |> Schema.edit_changeset(params)
    |> Mrgr.Repo.update()
  end

  def delete(tab) do
    Mrgr.Repo.delete(tab)
  end

  def delete_all_for_installation(installation) do
    Schema
    |> Query.for_installation(installation.id)
    |> Mrgr.Repo.all()
    |> Enum.map(&delete/1)
  end

  def draft_statuses do
    [
      %{
        id: 1,
        value: "ready_for_review"
      },
      %{
        id: 2,
        value: "draft"
      },
      %{
        id: 3,
        value: "both"
      }
    ]
  end

  def update_draft_status(tab, status) do
    tab
    |> Schema.draft_status_changeset(%{draft_status: status})
    |> Mrgr.Repo.update!()
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

  def draft_status_selected?(%{draft_status: status}, status), do: true
  def draft_status_selected?(_tab, _different_status), do: false

  def author_present?(%{authors: authors}, member) do
    authors
    |> Enum.map(& &1.id)
    |> Enum.member?(member.id)
  end

  def reviewer_present?(%{reviewers: reviewers}, member) do
    reviewers
    |> Enum.map(& &1.id)
    |> Enum.member?(member.id)
  end

  def toggle_reviewer(tab, member) do
    tab
    |> reviewer_present?(member)
    |> case do
      true ->
        remove_reviewer(tab, member)

      false ->
        add_reviewer(tab, member)
    end
  end

  def add_reviewer(tab, member) do
    params = %{pr_tab_id: tab.id, reviewer_id: member.id}

    %Mrgr.Schema.ReviewerPRTab{}
    |> Ecto.Changeset.change(params)
    |> Mrgr.Repo.insert!()

    Mrgr.Repo.preload(tab, :reviewers, force: true)
  end

  def remove_reviewer(tab, member) do
    Mrgr.Schema.ReviewerPRTab
    |> Mrgr.Repo.get_by(pr_tab_id: tab.id, reviewer_id: member.id)
    |> Mrgr.Repo.delete()

    Mrgr.Repo.preload(tab, :reviewers, force: true)
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

    def with_settings(query) do
      query
      |> with_authors()
      |> with_reviewers()
      |> with_labels()
      |> with_repositories()
    end

    def for_user(query, user) do
      from(q in query,
        where: q.user_id == ^user.id,
        where: q.installation_id == ^user.current_installation_id,
        join: u in assoc(q, :user),
        preload: [user: u]
      )
    end

    def for_installation(query, installation_id) do
      from(q in query,
        where: q.installation_id == ^installation_id
      )
    end

    def with_user(query) do
      from(q in query,
        join: u in assoc(q, :user),
        join: i in assoc(u, :current_installation),
        preload: [user: {u, current_installation: i}]
      )
    end

    def with_authors(query) do
      from(q in query,
        left_join: a in assoc(q, :authors),
        preload: [authors: a]
      )
    end

    def with_reviewers(query) do
      from(q in query,
        left_join: r in assoc(q, :reviewers),
        preload: [reviewers: r]
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
