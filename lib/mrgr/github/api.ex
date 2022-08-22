defmodule Mrgr.Github.API do
  @mod Application.compile_env!(:mrgr, :github)[:implementation]

  defdelegate commits(merge, installation), to: @mod
  defdelegate fetch_filtered_pulls(client, owner, name, opts), to: @mod
  defdelegate fetch_members(client, login), to: @mod
  defdelegate files_changed(merge, installation), to: @mod
  defdelegate get_new_installation_token(client, external_id), to: @mod
  defdelegate head_commit(merge, installation), to: @mod
  defdelegate merge_pull_request(client, owner, repo, number, message), to: @mod
end
