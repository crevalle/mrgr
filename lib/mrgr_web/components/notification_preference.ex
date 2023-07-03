defmodule MrgrWeb.Components.NotificationPreference do
  use MrgrWeb, :component
  use Mrgr.Notification.Event

  import MrgrWeb.Components.Form

  def preference_row(assigns) do
    ~H"""
    <.live_component
      module={MrgrWeb.Components.Live.NotificationPreferenceRow}
      id={"preference-row-#{@preference.id}"}
      preference={@preference}
      slack_unconnected={@slack_unconnected}
    />
    """
  end

  def preference_form(%{preference: %{event: @big_pr}} = assigns) do
    ~H"""
    <%= form_for @changeset, "#", [class: "flex space-x-2 items-center", phx_change: "preference-updated", phx_target: @target], fn f -> %>
      <%= label(f, :big_pr_threshold, "LOC Threshold", class: "text-sm font-medium text-gray-700") %>
      <.input field={f[:big_pr_threshold]} type="number" min="1" class="w-24 p-1" />
    <% end %>
    """
  end

  def preference_form(assigns), do: ~H[]
end
