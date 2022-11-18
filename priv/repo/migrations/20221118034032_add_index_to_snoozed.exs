defmodule Mrgr.Repo.Migrations.AddIndexToSnoozed do
  use Ecto.Migration

  def change do
    create index(:pull_requests, :snoozed_until)
  end
end
