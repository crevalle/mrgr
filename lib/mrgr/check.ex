defmodule Mrgr.Check do
  alias Mrgr.Schema.Check, as: Schema

  def toggle(check, user) do
    case Schema.complete?(check) do
      true -> uncomplete(check, user)
      false -> complete(check, user)
    end
  end

  def complete(check, user) do
    %Mrgr.Schema.CheckApproval{}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:check, check)
    |> Mrgr.Repo.insert!()

    check
    |> Mrgr.Repo.preload(:completer, force: true)
  end

  def uncomplete(check, user) do
    check
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:check_approval, nil)
    |> Mrgr.Repo.update!()
  end
end
