defmodule Mrgr.Github do
  # ********** ONLY TAKES HTE FIRST PAGE  *************
  # the first page is usually 30 results
  def parse(data) when is_list(data) do
    data
    |> List.first()
    |> parse()
  end

  def parse({_code, data, _response}), do: data

  def parse_into(response, module) when is_list(response) do
    Enum.map(response, &parse_into(&1, module))
  end

  def parse_into(response, module) do
    result = parse(response)
    module.new(result)
  end

  def process(%{"action" => "created", "installation" => _params} = payload) do
    create_installation(payload)
  end

  def process(%{"action" => "deleted", "installation" => _params} = payload) do
    delete_installation(payload)
  end

  def process(%{"action" => "requested", "installation" => _params} = payload) do
    payload
  end

  def process(%{"action" => "opened", "pull_request" => _params} = payload) do
    payload
  end

  # HEAD IS UPDATED
  def process(%{"action" => "synchronize", "pull_request" => _params} = payload) do
    IO.inspect("GOT SYNCHRONIZE")
    payload
  end

  def process(%{"action" => "requested", "check_suite" => _params} = payload) do
    Mrgr.CheckRun.process(payload)
  end

  # suspended?
  def process(payload), do: payload

  def create_installation(payload) do
    repository_params = payload["repositories"]

    sender = Mrgr.Github.User.new(payload["sender"])

    creator = Mrgr.User.find(sender)

    {:ok, installation} =
      payload
      |> Map.get("installation")
      |> Map.merge(%{"creator_id" => creator.id, "repositories" => repository_params})
      |> Mrgr.Schema.Installation.create_changeset()
      |> Mrgr.Repo.insert()

    # TODO: tokens
    # {:ok, token} = Mrgr.Installation.create_access_token(installation)

    # {:ok, installation, token}

    # create memberships
    # members = Mrgr.Installation.members(installation, token)
    # Mrgr.Installation.add_team_members(installation, members)
    {:ok, installation}
  end

  def delete_installation(payload) do
    external_id = payload["installation"]["id"]

    Mrgr.Schema.Installation
    |> Mrgr.Repo.get_by(external_id: external_id)
    |> case do
      nil ->
        nil

      installation ->
        Mrgr.Repo.delete(installation)
    end
  end

  def create_access_token() do
    # curl -i -X POST \
    # -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJKb2tlbiIsImV4cCI6MTYzMzIzMTAzOCwiaWF0IjoxNjMzMjMwNDM4LCJpc3MiOjEzOTk3MywianRpIjoiMnFsNmNyZ3ZqbzgycjNvcWxvMDAwM3YzIiwibmJmIjoxNjMzMjMwNDM4fQ.wuKhT5hRR3lNm3JISWSwPp628ZmtS6JT19KHjX2pMgzcAtSVFYV0Z0i7AoBQyMI41SO0HDnIqXzWuLLpGVn_ThhYdPDgMZB5fPaKuwcQn7WPpcirnyK2kPFVkeW23e3BDlxhQCDCkXxjOYBO2AVh9_XtRGlQ4Vo9vd3VEtSYAYaz9bfAkW8rs1_dNVid9O3d9L_p00TIkbL2n-ATzEsuy_xu9amKUudurrhyYOeGBLHfFpd6Vl5aY3cZaekyYXB1MMgbl31oy7BFOUttmDi5FboZtljhnjFDtPXhjQbFFYO3eupRNswS69X87mp8H-j2hyG38M2fQ_Pf79q8oDF25Q" \
    # -H "Accept: application/vnd.github.v3+json" \
    # https://api.github.com/app/installations/19871584/access_tokens
    # https://api.github.com/app/installations/19888521/access_tokens
  end
end
