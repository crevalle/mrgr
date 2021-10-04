defmodule Mrgr.Github do
  # ********** ONLY TAKES HTE FIRST PAGE  *************
  # the first page is usually 30 results
  def parse(data) when is_list(data) do
    data
    |> List.first()
    |> parse()
  end

  def parse({_code, data, _response}), do: data

  def process(%{"action" => "created"} = payload) do
    create_installation(payload)
  end

  def process(%{"action" => "deleted"} = payload) do
    delete_installation(payload)
  end

  def create_installation(payload) do
    repository_params = payload["repositories"]

    sender = Mrgr.Github.User.new(payload["sender"])

    creator = Mrgr.User.find(sender)

    {:ok, installation} =
      payload
      |> Map.get("installation")
      |> Map.merge(%{"creator_id" => creator.id, "repositories" => repository_params})
      |> Mrgr.Schema.Installation.create_changeset()
      |> Mrgr.Repo.insert()

    # TODO: tokens
    # {:ok, token} = Mrgr.Installation.create_access_token(installation)

    # {:ok, installation, token}

    {:ok, installation}
  end

  def delete_installation(payload) do
    external_id = payload["installation"]["id"]

    Mrgr.Schema.Installation
    |> Mrgr.Repo.get_by(external_id: external_id)
    |> case do
      nil ->
        nil

      installation ->
        Mrgr.Repo.delete(installation)
    end
  end
end
