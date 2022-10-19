defmodule Mrgr.Repository.Webhook do
  @spec create(Mrgr.Github.Webhook.t()) :: list() | {:error, :not_found}
  def create(payload) do
    with {:ok, installation} <- fetch_installation(payload) do
      Enum.map(payload["repositories_added"], fn attrs ->
        attrs
        |> Map.put("installation_id", installation.id)
        |> Mrgr.Repository.create()
      end)
    end
  end

  defp fetch_installation(%{"installation" => %{"id" => external_id}}) do
    case Mrgr.Installation.find_by_external_id(external_id) do
      nil -> {:error, :not_found}
      installation -> {:ok, installation}
    end
  end
end
