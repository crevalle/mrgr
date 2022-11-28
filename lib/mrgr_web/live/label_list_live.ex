defmodule MrgrWeb.LabelListLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Repository

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      Mrgr.PubSub.subscribe_to_installation(current_user)

      labels = Mrgr.Label.for_installation(current_user.current_installation_id)
      repositories = Mrgr.Repository.all_for_installation(current_user.current_installation_id)

      socket
      |> assign(:labels, labels)
      |> assign(:repositories, repositories)
      |> assign(:form_object, %Mrgr.Schema.Label{})
      |> put_title("Labels")
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("add", _params, socket) do
    socket
    |> assign(:form_object, %Mrgr.Schema.Label{})
    |> noreply()
  end

  def handle_event("edit", %{"id" => id}, socket) do
    label =
      socket.assigns.labels
      |> Mrgr.List.find(id)

    socket
    |> assign(:form_object, label)
    |> noreply()
  end

  def handle_info(%{event: @label_created, payload: label}, socket) do
    labels = [label | socket.assigns.labels]
    # sort them

    socket
    |> Flash.put(:info, "Label #{label.name} was added.")
    |> assign(:labels, labels)
    |> noreply()
  end

  def handle_info(%{event: @label_updated, payload: label}, socket) do
    labels = Mrgr.List.replace(socket.assigns.labels, label)

    socket
    |> Flash.put(:info, "Label #{label.name} was added.")
    |> assign(:labels, labels)
    |> noreply()
  end

  def handle_info(%{event: @label_deleted, payload: label}, socket) do
    labels = Mrgr.List.remove(socket.assigns.labels, label)

    socket
    |> Flash.put(:info, "Label #{label.name} was deleted.")
    |> assign(:labels, labels)
    |> noreply()
  end

  def handle_info(%{event: _whatevs}, socket), do: noreply(socket)

  def selected?(label, nil), do: false
  #
  # new label form.  everything is selected
  def selected_repository_ids(repos, %{id: nil}), do: Enum.map(repos, & &1.id)

  def selected_repository_ids(_repos, label) do
    Enum.map(label.label_repositories, & &1.repository_id)
  end
end
