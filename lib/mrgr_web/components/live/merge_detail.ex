defmodule MrgrWeb.Components.Live.MergeDetail do
  use MrgrWeb, :live_component
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Merge

  def handle_event("merge", %{"merge" => params}, socket) do
    id = String.to_integer(params["id"])
    message = params["message"]

    Mrgr.Merge.merge!(id, message, socket.assigns.current_user)
    |> case do
      {:ok, _merge} ->
        socket
        |> put_flash(:info, "OK! 🥳")
        |> noreply()

      {:error, message} ->
        socket
        |> put_flash(:error, message)
        |> noreply()
    end
  end

  def external_merge_url(merge) do
    Mrgr.Schema.Merge.external_merge_url(merge)
  end

  def merge_frozen?(repos, repo) do
    Mrgr.List.present?(repos, repo)
  end
end
