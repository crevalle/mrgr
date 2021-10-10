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

  def find(schema, external_id) do
    Mrgr.Repo.get_by(schema, external_id)
  end
end
