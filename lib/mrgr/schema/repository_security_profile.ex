defmodule Mrgr.Schema.RepositorySecurityProfile do
  use Mrgr.Schema

  schema "repository_security_profiles" do
    field(:title, :string)
    field(:apply_to_new_repos, :boolean)

    belongs_to(:installation, Mrgr.Schema.Installation)

    embeds_one(:settings, Mrgr.Schema.RepositorySecuritySettings, on_replace: :delete)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:title, :apply_to_new_repos, :installation_id])
    |> validate_required([:title, :apply_to_new_repos, :installation_id])
    |> cast_embed(:settings)
    |> foreign_key_constraint(:installation_id)
  end
end
