defmodule Mrgr.Github.Commit.Commit do
  use Mrgr.Github.Schema

  embedded_schema do
    embeds_one(:author, Mrgr.Github.Commit.ShortUser, on_replace: :update)
    embeds_one(:committer, Mrgr.Github.Commit.ShortUser, on_replace: :update)

    field(:comment_count, :integer)
    field(:message, :string)
    field(:url, :string)
    field(:verification, :map)

    # "author" => %{
    # "date" => "2022-08-01T04:54:19Z",
    # "email" => "desmond@crevalle.io",
    # "name" => "Desmond Bowe"
    # },
    # "comment_count" => 0,
    # "committer" => %{
    # "date" => "2022-08-02T05:20:52Z",
    # "email" => "desmond@crevalle.io",
    # "name" => "Desmond Bowe"
    # },
    # "message" => "WIP",
    # "tree" => %{
    # "sha" => "ee099f52c2105ff50cadd4382a35ab423b9da8c7",
    # "url" => "https://api.github.com/repos/crevalle/mrgr/git/trees/ee099f52c2105ff50cadd4382a35ab423b9da8c7"
    # },
    # "url" => "https://api.github.com/repos/crevalle/mrgr/git/commits/adb9cb04fb15a5214dc015c718f9563b9a31ba95",
    # "verification" => %{
    # "payload" => nil,
    # "reason" => "unsigned",
    # "signature" => nil,
    # "verified" => false
    # }
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:comment_count, :message, :url, :verification])
    |> cast_embed(:author)
    |> cast_embed(:committer)
  end
end
