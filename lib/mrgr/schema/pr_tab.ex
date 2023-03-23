defmodule Mrgr.Schema.PRTab do
  use Mrgr.Schema

  @draft_statuses ["open", "draft", "both"]

  schema "pr_tabs" do
    field(:draft_status, :string, default: "open")
    field(:title, :string)
    field(:permalink, :string)

    field(:meta, :map, default: %{}, virtual: true)
    field(:type, :string, virtual: true, default: "custom")
    field(:editing, :boolean, default: false, virtual: true)

    field(:pull_requests, {:array, :map}, default: [], virtual: true)

    belongs_to(:user, Mrgr.Schema.User)

    has_many(:author_pr_tabs, Mrgr.Schema.AuthorPRTab)
    has_many(:authors, through: [:author_pr_tabs, :author])

    has_many(:reviewer_pr_tabs, Mrgr.Schema.ReviewerPRTab)
    has_many(:reviewers, through: [:reviewer_pr_tabs, :reviewer])

    has_many(:label_pr_tabs, Mrgr.Schema.LabelPRTab)
    has_many(:labels, through: [:label_pr_tabs, :label])

    has_many(:repository_pr_tabs, Mrgr.Schema.RepositoryPRTab)
    has_many(:repositories, through: [:repository_pr_tabs, :repository])

    timestamps()
  end

  @allowed ~w[
    title
    permalink
    user_id
  ]a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @allowed)
    |> set_default_title()
    |> set_permalink()
    |> validate_required([:user_id])
  end

  def edit_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:title])
    |> set_default_title()
    |> set_permalink()
  end

  def draft_status_changeset(schema, params) do
    schema
    |> cast(params, [:draft_status])
    |> validate_inclusion(:draft_status, @draft_statuses)
  end

  def set_default_title(changeset) do
    case get_change(changeset, :title) do
      empty when empty in [nil, ""] ->
        put_change(changeset, :title, generate_random_tab_name())

      _title ->
        changeset
    end
  end

  def set_permalink(changeset) do
    title = get_change(changeset, :title)

    put_change(changeset, :permalink, generate_permalink(title))
  end

  def generate_permalink(title) do
    # keep only alphanumerics and the hyphen
    title
    |> String.downcase()
    |> String.replace(" ", "-")
    |> String.replace(~r"[^a-z0-9-]", "")
  end

  def generate_random_tab_name do
    # four digit number
    random_number = 10000 - :rand.uniform(10000)
    "Tab #{random_number}"
  end
end
