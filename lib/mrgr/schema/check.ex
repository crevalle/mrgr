defmodule Mrgr.Schema.Check do
  use Mrgr.Schema

  schema "checks" do
    belongs_to(:checklist, Mrgr.Schema.Checklist)

    field(:text, :string)

    has_one(:check_approval, Mrgr.Schema.CheckApproval,
      on_delete: :delete_all,
      on_replace: :delete
    )

    has_one(:completer, through: [:check_approval, :user])

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:text])
  end

  def complete_changeset(schema, params) do
    schema
    |> cast(params, [])
    |> cast_assoc(:check_approval, [params.check_approval])
  end

  def complete?(%{check_approval: %Mrgr.Schema.CheckApproval{}}), do: true
  def complete?(_), do: false
end
