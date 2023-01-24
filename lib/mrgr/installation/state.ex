defmodule Mrgr.Installation.State do
  def set_created(installation) do
    update_state!(installation, "created")
  end

  def set_syncing_initial_data(installation) do
    update_state!(installation, "syncing_initial_data")
  end

  def set_initial_data_sync_complete(installation) do
    update_state!(installation, "initial_data_sync_complete")
  end

  def set_active(installation) do
    update_state!(installation, "active")
  end

  def update_state!(installation, state) do
    installation
    |> Mrgr.Schema.Installation.state_changeset(%{state: state})
    |> Mrgr.Repo.update!()
  end

  def onboarding_complete?(%{state: "active"}), do: true
  def onboarding_complete?(_installation), do: false

  def data_synced?(%{state: state}) when state in ["initial_data_sync_complete", "active"],
    do: true

  def data_synced?(_installation), do: false
end
