defmodule Mrgr.User do
  alias Mrgr.Schema.User, as: Schema

  @spec find(integer()) :: Schema.t() | nil
  def find(id) do
    Mrgr.Repo.get(Schema, id)
  end

  @spec find_or_create(map()) :: Schema.t()
  def find_or_create(params) do
    case find_by_email(params.email) do
      %Schema{} = user ->
        user

      nil ->
        {:ok, user} = create(params)
        user
    end
  end

  @spec find_by_email(String.t()) :: Schema.t() | nil
  def find_by_email(email) do
    Mrgr.Repo.get_by(Schema, email: email)
  end

  @spec create(map()) :: {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    params
    |> Schema.create_changeset()
    |> Mrgr.Repo.insert()
  end
end
