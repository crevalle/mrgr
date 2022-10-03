defmodule Mrgr.Schema.CheckApproval do
  use Mrgr.Schema

  schema "check_approvals" do
    belongs_to(:check, Mrgr.Schema.Check)
    belongs_to(:user, Mrgr.Schema.User)

    timestamps()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:check_id, :user_id])
    |> put_associations()
  end

  defp put_associations(changeset) do
    user = changeset.params["user"]
    check = changeset.params["check"]

    changeset
    |> put_assoc(:user, user)
    |> put_assoc(:check, check)
  end
end
