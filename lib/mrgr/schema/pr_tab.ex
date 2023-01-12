defmodule Mrgr.Schema.PRTab do
  use Mrgr.Schema

  schema "pr_tabs" do
    field(:title, :string)

    field(:meta, :map, default: %{}, virtual: true)
    field(:viewing_snoozed, :boolean, default: false, virtual: true)
    field(:snoozed, :string, virtual: true)
    field(:type, :string, virtual: true)

    field(:pull_requests, {:array, :map}, default: [], virtual: true)

    belongs_to(:user, Mrgr.Schema.User)

    has_many(:author_pr_tabs, Mrgr.Schema.AuthorPRTab)
    has_many(:authors, through: [:author_pr_tabs, :author])

    has_many(:label_pr_tabs, Mrgr.Schema.LabelPRTab)
    has_many(:labels, through: [:label_pr_tabs, :label])

    timestamps()
  end

  @allowed ~w[
    title
    user_id
  ]a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @allowed)
    |> validate_required([:user_id])
  end
end
