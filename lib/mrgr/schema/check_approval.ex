defmodule Mrgr.Schema.CheckApproval do
  use Mrgr.Schema

  schema "check_approvals" do
    belongs_to(:check, Mrgr.Schema.Check)
    belongs_to(:user, Mrgr.Schema.User)

    timestamps()
  end
end
