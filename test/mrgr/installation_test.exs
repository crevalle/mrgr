defmodule Mrgr.InstallationTest do
  use Mrgr.DataCase

  describe "sync_repositories/1" do
    test "fetches repo data from github and creates repos in the installation" do
      installation = insert!(:installation)

      i = Mrgr.Installation.sync_repositories(installation)

      assert Enum.count(i.repositories) == 3

      languages = Enum.map(i.repositories, & &1.language)

      assert languages == ["Elixir", "Ruby", "JavaScript"]
    end
  end
end
