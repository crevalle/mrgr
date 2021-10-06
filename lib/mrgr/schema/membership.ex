defmodule Mrgr.Schema.Membership do
  use Mrgr.Schema

  schema "memberships" do
    field(:active, :boolean)

    belongs_to(:member, Mrgr.Schema.Member)
    belongs_to(:installation, Mrgr.Schema.Installation)

    timestamps()
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, [:member_id, :installation_id, :active])
    |> foreign_key_constraint(:member_id)
    |> foreign_key_constraint(:installation_id)
  end
end
