defmodule Mrgr.Label.Webhook do
  def create(payload) do
    with {:ok, repository} <- find_repository(payload) do
      Mrgr.Label.find_or_create_for_repo(payload["label"], repository)
    end
  end

  def update(payload) do
    with {:ok, lr} <- find_association(payload) do
      Mrgr.Label.update_from_webhook(lr, payload["label"], payload["changes"])
    end
  end

  def delete(payload) do
    with {:ok, lr} <- find_association(payload) do
      Mrgr.Label.delete_from_webhook(lr)
    end
  end

  def find_association(%{"label" => %{"node_id" => node_id}}) do
    case Mrgr.Label.find_association_by_node_id(node_id) do
      nil -> {:error, :not_found}
      lr -> {:ok, lr}
    end
  end

  def find_repository(%{"repository" => %{"node_id" => node_id}}) do
    case Mrgr.Repository.find_by_node_id(node_id) do
      nil -> {:error, :not_found}
      repository -> {:ok, repository}
    end
  end

  def find_repository(_), do: {:error, :bad_params}
end
