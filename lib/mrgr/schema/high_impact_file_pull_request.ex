defmodule Mrgr.Schema.HighImpactFilePullRequest do
  use Mrgr.Schema

  schema "high_impact_file_pull_requests" do
    belongs_to(:pull_request, Mrgr.Schema.PullRequest)
    belongs_to(:high_impact_file, Mrgr.Schema.HighImpactFile)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:pull_request_id, :high_impact_file_id])
    |> foreign_key_constraint(:pull_request_id)
    |> foreign_key_constraint(:high_impact_file_id)
  end
end
