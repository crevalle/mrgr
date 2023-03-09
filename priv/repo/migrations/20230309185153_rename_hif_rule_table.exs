defmodule Mrgr.Repo.Migrations.RenameHIFRuleTable do
  use Ecto.Migration

  def up do
    rename table("high_impact_files"), to: table("high_impact_file_rules")

    rename table("high_impact_file_pull_requests"),
      to: table("high_impact_file_rule_pull_requests")

    # foreign-key column
    rename table("high_impact_file_rule_pull_requests"), :high_impact_file_id,
      to: :high_impact_file_rule_id
  end

  def down do
    # foreign-key column
    rename table("high_impact_file_rule_pull_requests"), :high_impact_file_id,
      to: :high_impact_file_id

    rename table("high_impact_file_pull_requests"), to: table("high_impact_file_pull_requests")
    rename table("high_impact_file_rules"), to: table("high_impact_file_rules")
  end
end
