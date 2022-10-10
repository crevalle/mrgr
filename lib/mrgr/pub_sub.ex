defmodule Mrgr.PubSub do
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(__MODULE__, topic)
  end

  def broadcast(payload, topic, event) do
    data = %{payload: payload, topic: topic, event: event}
    IO.inspect(event, label: "PUBLISHING")
    Phoenix.PubSub.broadcast(__MODULE__, topic, data)
  end

  defmodule Topic do
    def installation(%Mrgr.Schema.Installation{id: id}), do: installation(id)

    def installation(%{current_installation_id: id}), do: installation(id)

    def installation(%{installation_id: id}), do: installation(id)

    def installation(id) do
      "installation:#{id}"
    end

    def admin, do: "admin"
  end

  defmodule Event do
    defmacro __using__(_opts) do
      quote do
        @incoming_webhook_created "incoming_webhook:created"

        @branch_pushed "branch:pushed"

        @file_change_alert_created "file_change_alert:created"
        @file_change_alert_updated "file_change_alert:updated"
        @file_change_alert_deleted "file_change_alert:deleted"

        @merge_created "merge:created"
        @merge_edited "merge:edited"
        @merge_reopened "merge:reopened"
        @merge_synchronized "merge:synchronized"
        @merge_closed "merge:closed"
        @merge_comment_created "merge:comment_created"
        @merge_assignees_updated "merge:assignees_updated"
        @merge_reviewers_updated "merge:reviewers_updated"

        @api_request_completed "api_request:completed"
      end
    end
  end
end
