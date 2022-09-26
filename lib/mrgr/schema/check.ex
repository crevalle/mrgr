defmodule Mrgr.Schema.Check do
  use Mrgr.Schema

  schema "checks" do
    belongs_to(:checklist, Mrgr.Schema.Checklist)

    field(:text, :string)

    has_many(:check_approvals, Mrgr.Schema.CheckApproval, on_delete: :delete_all)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:text])
  end
end
