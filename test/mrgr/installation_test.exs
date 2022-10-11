defmodule Mrgr.InstallationTest do
  use Mrgr.DataCase

  describe "create_repositories/1" do
    test "fetches repo data from github and creatse repos in the installation" do
      installation = insert!(:installation)

      i = Mrgr.Installation.create_repositories(installation)

      assert Enum.count(i.repositories) == 2

      languages = Enum.map(i.repositories, & &1.language)

      assert languages == ["JavaScript", "Ruby"]
    end
  end
end
