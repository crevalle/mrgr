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
end
