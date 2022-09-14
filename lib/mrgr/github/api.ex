defmodule Mrgr.Github.API do
  @mod Application.compile_env!(:mrgr, :github)[:implementation]

  defdelegate commits(merge, installation), to: @mod
  defdelegate fetch_filtered_pulls(installation, repo, opts), to: @mod
  defdelegate fetch_members(installation), to: @mod
  defdelegate files_changed(merge, installation), to: @mod
  defdelegate get_new_installation_token(installation), to: @mod
  defdelegate head_commit(merge, installation), to: @mod
  defdelegate merge_pull_request(client, owner, repo, number, message), to: @mod
end
