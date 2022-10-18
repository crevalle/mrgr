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
        |> noreply()

      {:error, message} ->
        socket
        |> Flash.put(:error, message)
        |> noreply()
    end
  end

  def external_merge_url(merge) do
    Mrgr.Schema.Merge.external_merge_url(merge)
  end
end
