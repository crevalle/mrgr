defmodule Mrgr.RepositoryTest do
  use Mrgr.DataCase

  describe "create_for_installation/1" do
    test "fetches repo data from github and creates repos in the installation" do
      installation = insert!(:installation)

      i = Mrgr.Repository.create_for_installation(installation)

      assert Enum.count(i.repositories) == 3

      languages = Enum.map(i.repositories, & &1.language)

      assert languages == ["JavaScript", "Ruby", "Elixir"]
    end
  end

  describe "generate_default_file_change_alerts/1" do
    test "creates default file change alerts according to repo language" do
      %{id: id} = r = insert!(:repository, language: "Elixir")

      fcas =
        Mrgr.Repository.generate_default_file_change_alerts(r)
        |> Enum.map(&Mrgr.Tuple.take_value/1)

      assert [
               %{
                 badge_text: "migration",
                 pattern: "priv/repo/migrations/*",
                 bg_color: "#dcfce7",
                 notify_user: true,
                 repository_id: ^id,
                 source: :system
               },
               %{
                 badge_text: "router",
                 pattern: "lib/**/router.ex",
                 bg_color: "#dbeafe",
                 notify_user: true,
                 repository_id: ^id,
                 source: :system
               },
               %{
                 badge_text: "dependencies",
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

      assert Mrgr.Repository.generate_default_file_change_alerts(r) == []
    end
  end
end
