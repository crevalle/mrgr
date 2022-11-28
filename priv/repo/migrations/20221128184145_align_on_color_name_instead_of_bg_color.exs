defmodule Mrgr.Repo.Migrations.AlignOnColorNameInsteadOfBGColor do
  use Ecto.Migration

  def change do
    rename table(:labels), :bg_color, to: :color
    rename table(:file_change_alerts), :bg_color, to: :color
  end
end
