defmodule Mrgr.Github do
  def find(schema, external_id) do
    Mrgr.Repo.get_by(schema, external_id: external_id)
  end
end
