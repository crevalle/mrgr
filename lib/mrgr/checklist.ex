defmodule Mrgr.Checklist do
  alias Mrgr.Schema.Checklist, as: Schema

  def create!(attrs) do
    %Schema{}
    |> Schema.create_changeset(attrs)
    |> Mrgr.Repo.insert!()
  end

  def delete(checklist) do
    Mrgr.Repo.delete(checklist)
  end

  def complete?(%Schema{} = checklist) do
    Enum.all?(checklist.checks, &Mrgr.Schema.Check.complete?/1)
  end

  # intentionally not handling %Ecto.AssociationNotLoaded{} so I don't
  # accidentally forget to load it
  def complete?(nil), do: false
end
