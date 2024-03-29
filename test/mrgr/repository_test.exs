defmodule Mrgr.RepositoryTest do
  use Mrgr.DataCase

  describe "generate_default_high_impact_file_rules/1" do
    test "creates default file change alerts according to repo language" do
      %{id: id} = r = insert!(:repository, language: "Elixir")

      %{high_impact_file_rules: hifs} = Mrgr.Repository.generate_default_high_impact_file_rules(r)

      assert [
               %{
                 name: "migration",
                 pattern: "priv/repo/migrations/*",
                 color: "dcfce7",
                 email: true,
                 repository_id: ^id,
                 source: :system
               },
               %{
                 name: "router",
                 pattern: "lib/**/router.ex",
                 color: "dbeafe",
                 email: true,
                 repository_id: ^id,
                 source: :system
               },
               %{
                 name: "dependencies",
                 pattern: "mix.lock",
                 color: "fef9c3",
                 email: true,
                 repository_id: ^id,
                 source: :system
               }
             ] = hifs
    end

    test "creates nothing if repo language is unsupported" do
      r = insert!(:repository, language: "que")

      %{high_impact_file_rules: hifs} = Mrgr.Repository.generate_default_high_impact_file_rules(r)
      assert hifs == []
    end
  end
end
