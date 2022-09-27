defmodule Mrgr.CheckTest do
  use Mrgr.DataCase

  describe "complete/2" do
    test "creates an approval between the check and the user" do
      check = insert!(:check) |> Mrgr.Repo.preload(:completer)
      user = insert!(:user)

      completed =
        Mrgr.Check.complete(check, user)
        |> Mrgr.Repo.preload(:completer, force: true)

      assert completed.completer.id == user.id
      assert completed.check_approval.inserted_at
    end
  end

  describe "uncomplete/2" do
    test "removes an approval" do
      check = insert!(:check) |> Mrgr.Repo.preload(:completer)
      user = insert!(:user)

      completed = Mrgr.Check.complete(check, user)

      Mrgr.Check.uncomplete(completed, user)
      |> Mrgr.Repo.preload(:completer, force: true)

      approval = Mrgr.Repo.get_by(Mrgr.Schema.CheckApproval, user_id: user.id, check_id: check.id)
      assert is_nil(approval)
    end
  end
end
