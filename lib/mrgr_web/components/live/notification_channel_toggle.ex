defmodule MrgrWeb.Components.Live.NotificationChannelToggle do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex space-x-2 items-center justify-center">
      <.tooltip
        class="pl-2"
        phx-click={JS.push("toggle-channel", value: %{id: @obj.id, attr: "email"})}
        phx-target={@myself}
      >
        <%= if @obj.email do %>
          <.email_enabled_icon />
        <% else %>
          <.email_disabled_icon />
        <% end %>
        <:text>
          <%= if @obj.email do %>
            Email alerts enabled.
          <% else %>
            Email alerts disabled.
          <% end %>
        </:text>
      </.tooltip>

      <%= if @slack_unconnected do %>
        <.tooltip class="pl-2">
          <%= img_tag("/images/Slack-mark-black-RGB.png", class: "w-4 h-4 opacity-40 toggle disabled") %>
          <:text>
            Connect Slack to receive notifications.
          </:text>
        </.tooltip>
      <% else %>
        <.tooltip
          class="pl-2"
          phx-click={JS.push("toggle-channel", value: %{id: @obj.id, attr: "slack"})}
          phx-target={@myself}
        >
          <%= if @obj.slack do %>
            <.slack_enabled_icon />
          <% else %>
            <.slack_disabled_icon />
          <% end %>
          <:text>
            <%= if @obj.slack do %>
              Slack alerts enabled.
            <% else %>
              Slack alerts disabled.
            <% end %>
          </:text>
        </.tooltip>
      <% end %>
    </div>
    """
  end

  def handle_event("toggle-channel", %{"attr" => attr}, socket) do
    obj =
      socket.assigns.obj
      |> Mrgr.Notification.Schema.toggle_channel(attr)

    send(self(), {:channel_updated, obj})

    socket
    |> noreply()
  end
end
