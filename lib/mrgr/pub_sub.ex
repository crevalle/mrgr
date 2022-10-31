defmodule Mrgr.PubSub do
  def subscribe_to_installation(user) do
    user
    |> Mrgr.PubSub.Topic.installation()
    |> subscribe()
  end

  def subscribe_to_flash(user) do
    user
    |> Mrgr.PubSub.Topic.flash()
    |> subscribe()
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(__MODULE__, topic)
  end

  def broadcast_flash(user, key, message) do
    topic = Mrgr.PubSub.Topic.flash(user)

    Mrgr.PubSub.broadcast(message, topic, "flash:#{key}")
  end

  def broadcast(payload, topic, event) do
    data = %{payload: payload, topic: topic, event: event}
    Phoenix.PubSub.broadcast(__MODULE__, topic, data)
  end

  defmodule Topic do
    def flash(user) do
      "user:#{user.id}"
    end

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
        @api_request_completed "api_request:completed"

        @branch_pushed "branch:pushed"

        @file_change_alert_created "file_change_alert:created"
        @file_change_alert_updated "file_change_alert:updated"
        @file_change_alert_deleted "file_change_alert:deleted"

        @flash_info "flash:info"
        @flash_error "flash:error"

        @incoming_webhook_created "incoming_webhook:created"
        @installation_setup_completed "installation:setup_completed"
        @installation_loading_members "installation:loading_members"
        @installation_loading_repositories "installation:loading_repositories"
        @installation_loading_merges "installation:loading_merges"

        @merge_created "merge:created"
        @merge_edited "merge:edited"
        @merge_reopened "merge:reopened"
        @merge_synchronized "merge:synchronized"
        @merge_closed "merge:closed"
        @merge_comment_created "merge:comment_created"
        @merge_assignees_updated "merge:assignees_updated"
        @merge_reviewers_updated "merge:reviewers_updated"
        @merge_reviews_updated "merge:reviews_updated"
      end
    end
  end
end
