defmodule Mrgr.Poke do
  alias Mrgr.Schema.Poke, as: Schema

  @spec create(Mrgr.Schema.PullRequest.t(), Mrgr.Schema.User.t(), String.t(), String.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  def create(pull_request, sender, type, message) do
    # expects a repo on the PR
    case post_to_github(pull_request, message) do
      {:ok, comment_data} ->
        params = %{
          pull_request_id: pull_request.id,
          sender_id: sender.id,
          type: type,
          message: message,
          node_id: comment_data["node_id"],
          url: comment_data["html_url"]
        }

        create_record(params)

      {:error, %{"message" => message}} ->
        {:error, message}
    end
  end

  @spec create_record(map()) :: {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_record(params) do
    %Schema{}
    |> Schema.changeset(params)
    |> Mrgr.Repo.insert()
  end

  def post_to_github(pull_request, message) do
    Mrgr.Github.API.create_comment(pull_request, message)
  end
end
