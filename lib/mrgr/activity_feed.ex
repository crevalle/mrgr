defmodule Mrgr.ActivityFeed do
  def load_for_user(%{current_installation_id: id}) do
    Mrgr.IncomingWebhook.for_installation(id)
  end
end
