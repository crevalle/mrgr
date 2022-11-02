defmodule Mrgr.Schema.RepositorySecurityProfile do
  use Mrgr.Schema

  schema "repository_security_profiles" do
    field(:apply_to_new_repos, :boolean)

    # installation has_one SecurityProfile.
    belongs_to(:installation, Mrgr.Schema.Installation)

    embeds_one(:settings, Mrgr.Schema.RepositorySecuritySettings)

    timestamps()
  end
end
