defmodule Mrgr.Repo.Migrations.RenameFCATextToName do
  use Ecto.Migration

  def change do
    rename table(:file_change_alerts), :badge_text, to: :name
  end
end
