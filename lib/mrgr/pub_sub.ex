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
        @installation_loading_pull_requests "installation:loading_pull_requests"

        @pull_request_created "pull_request:created"
        @pull_request_edited "pull_request:edited"
        @pull_request_reopened "pull_request:reopened"
        @pull_request_synchronized "pull_request:synchronized"
        @pull_request_closed "pull_request:closed"
        @pull_request_comment_created "pull_request:comment_created"
        @pull_request_assignees_updated "pull_request:assignees_updated"
        @pull_request_reviewers_updated "pull_request:reviewers_updated"
        @pull_request_reviews_updated "pull_request:reviews_updated"

        @security_profile_created "security_profile:created"
        @security_profile_updated "security_profile:updated"
        @security_profile_deleted "security_profile:deleted"
      end
    end
  end
end
