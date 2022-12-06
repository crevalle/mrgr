defmodule Mrgr.Schema.PullRequestLabel do
  use Mrgr.Schema

  schema "pull_request_labels" do
    belongs_to(:label, Mrgr.Schema.Label)
    belongs_to(:pull_request, Mrgr.Schema.Label)

    timestamps()
  end
end
