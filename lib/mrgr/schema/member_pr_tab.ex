defmodule Mrgr.Schema.MemberPRTab do
  use Mrgr.Schema

  schema "member_pr_tabs" do
    belongs_to(:user, Mrgr.Schema.User)
    belongs_to(:member, Mrgr.Schema.Member)

    timestamps()
  end

  @allowed ~w[
    member_id
    user_id
  ]a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @allowed)
    |> validate_required(@allowed)
  end
end
