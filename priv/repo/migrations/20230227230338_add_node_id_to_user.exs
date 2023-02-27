defmodule Mrgr.Repo.Migrations.AddNodeIDToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:node_id, :string)
    end

  end
end
