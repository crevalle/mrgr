defmodule Mrgr.Repo.Migrations.RemoveRepositoryFlatSettings do
  use Ecto.Migration

  def up do
    alter table(:repositories) do
      remove(:dismiss_stale_reviews)
      remove(:require_code_owner_reviews)
      remove(:required_approving_review_count)
    end
  end

  def down do
    # no goin' back
  end
end
