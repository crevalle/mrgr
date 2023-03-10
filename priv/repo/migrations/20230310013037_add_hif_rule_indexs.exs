defmodule Mrgr.Repo.Migrations.AddHifRuleIndexs do
  use Ecto.Migration

  def change do
    create index(:high_impact_file_rules, :user_id)
  end
end
