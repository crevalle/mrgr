defmodule Mrgr.Github do
  # ********** ONLY TAKES HTE FIRST PAGE  *************
  # the first page is usually 30 results
  def parse(data) when is_list(data) do
    data
    |> List.first()
    |> parse()
  end

  def parse({_code, data, _response}), do: data

  def parse_into({_code, data, _response}, module) when is_list(data) do
    Enum.map(data, &parse_into(&1, module))
  end

  def parse_into({_code, data, _response}, module) do
    parse_into(data, module)
  end

  def parse_into(response, module) when is_list(response) do
    Enum.map(response, &parse_into(&1, module))
  end

  def parse_into(data, module) do
    module.new(data)
  end

  def find(schema, external_id) do
    Mrgr.Repo.get_by(schema, external_id: external_id)
  end

  def write_json(data, location) do
    File.write(location, Jason.encode!(data), [:binary])
    data
  end

  def load_json(location) do
    {:ok, data} = File.read(location)
    Jason.decode!(data)
  end
end
