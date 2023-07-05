defmodule MrgrWeb.Components.Live.NotificationPreferenceRow do
  use MrgrWeb, :live_component

  import MrgrWeb.Components.NotificationPreference

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign(
      :changeset,
      changeset(assigns.preference.settings)
    )
    |> ok()
  end

  # paranoia from database default
  def changeset(nil), do: nil

  def changeset(settings) do
    Mrgr.Schema.UserNotificationPreference.the_settings_changeset(settings)
  end

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-3">
      <div class="separated-grid-row flex items-center">
        <p>
          <%= format_preference_name(@preference.event) %>
        </p>
      </div>
      <div class="separated-grid-row">
        <.preference_form preference={@preference} changeset={@changeset} target={@myself} />
      </div>
      <div class="separated-grid-row flex items-center justify-center">
        <.live_component
          module={MrgrWeb.Components.Live.NotificationChannelToggle}
          id={"preference-#{@preference.id}"}
          obj={@preference}
          slack_unconnected={@slack_unconnected}
        />
      </div>
    </div>
    """
  end

  def handle_event("preference-updated", attrs, socket) do
    # if they send us garbage it'll just reload the page

    preference =
      socket.assigns.preference
      |> Mrgr.Schema.UserNotificationPreference.settings_changeset(attrs)
      |> Mrgr.Repo.update!()

    send(self(), {:preference_updated, preference})

    socket
    |> noreply()
  end
end
