defmodule Mrgr.Github.AccessToken do
  use Mrgr.Schema

  @primary_key false
  embedded_schema do
    field(:expires_at, :utc_datetime)
    field(:permissions, :map)
    field(:repository_selection, :string)
    field(:token, :string)
  end

  def new(params) do
    %__MODULE__{}
    |> cast(params, [:expires_at, :permissions, :repository_selection, :token])
    |> apply_changes()
  end
end
