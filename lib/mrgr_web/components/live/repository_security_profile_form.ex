defmodule MrgrWeb.Components.Live.RepositorySecurityProfileForm do
  use MrgrWeb, :live_component

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign(:changeset, build_changeset(assigns.object))
    |> ok()
  end

  def handle_event("save", %{"repository_security_profile" => params}, socket) do
    object = socket.assigns.object

    res =
      case creating?(object) do
        true ->
          params
          |> Map.put("installation_id", socket.assigns.current_user.current_installation.id)
          |> Mrgr.RepositorySecurityProfile.create()

        false ->
          Mrgr.RepositorySecurityProfile.update(object, params)
      end

    case res do
      {:ok, _profile} ->
        close_me()

        socket
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> noreply()
    end
  end

  def handle_event("delete-profile", _params, socket) do
    profile = socket.assigns.object
    Mrgr.RepositorySecurityProfile.delete(profile)

    close_me()

    socket
    |> noreply()
  end

  def handle_event("close-form", _params, socket) do
    close_me()

    noreply(socket)
  end

  defp close_me do
    send(self(), :close_form)
  end

  defp build_changeset(schema \\ %Mrgr.Schema.RepositorySecurityProfile{}) do
    Mrgr.Schema.RepositorySecurityProfile.changeset(schema)
  end

  defp creating?(%{id: nil}), do: true
  defp creating?(_), do: false

  defp editing?(obj), do: !creating?(obj)
end
