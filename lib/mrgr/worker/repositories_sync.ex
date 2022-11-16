defmodule Mrgr.Worker.RepositoriesSync do
  use Oban.Worker, max_attempts: 3

  @impl true
  def perform(%{args: %{"type" => "all"}}) do
    # farm out each installation now
    Mrgr.Installation.all()
    |> Enum.map(fn i ->
      %{"installation_id" => i.id}
      |> new()
      |> Oban.insert!()
    end)

    :ok
  end

  def perform(%{args: %{"installation_id" => id}}) do
    id
    |> Mrgr.Installation.find()
    |> Mrgr.Installation.sync_repository_data()

    :ok
  end
end
