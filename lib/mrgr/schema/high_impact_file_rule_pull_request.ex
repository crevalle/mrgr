defmodule Mrgr.Schema.HighImpactFileRulePullRequest do
  use Mrgr.Schema

  schema "high_impact_file_rule_pull_requests" do
    belongs_to(:pull_request, Mrgr.Schema.PullRequest)
    belongs_to(:high_impact_file_rule, Mrgr.Schema.HighImpactFileRule)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:pull_request_id, :high_impact_file_rule_id])
    |> foreign_key_constraint(:pull_request_id)
    |> foreign_key_constraint(:high_impact_file_rule_id)
    |> unique_constraint(:pull_request_id,
      name: :high_impact_file_pull_requests_pull_request_id_high_impact_file
    )
  end
end
