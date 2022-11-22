defmodule Mrgr.RepositoryTest do
  use Mrgr.DataCase

  describe "generate_default_file_change_alerts/1" do
    test "creates default file change alerts according to repo language" do
      %{id: id} = r = insert!(:repository, language: "Elixir")

      %{file_change_alerts: fcas} = Mrgr.Repository.generate_default_file_change_alerts(r)

      assert [
               %{
                 name: "migration",
                 pattern: "priv/repo/migrations/*",
                 bg_color: "#dcfce7",
                 notify_user: true,
                 repository_id: ^id,
                 source: :system
               },
               %{
                 name: "router",
                 pattern: "lib/**/router.ex",
                 bg_color: "#dbeafe",
                 notify_user: true,
                 repository_id: ^id,
                 source: :system
               },
               %{
                 name: "dependencies",
                 pattern: "mix.lock",
                 bg_color: "#fef9c3",
                 notify_user: true,
                 repository_id: ^id,
                 source: :system
               }
             ] = fcas
    end

    test "creates nothing if repo language is unsupported" do
      r = insert!(:repository, language: "que")

      %{file_change_alerts: fcas} = Mrgr.Repository.generate_default_file_change_alerts(r)
      assert fcas == []
    end
  end
end
