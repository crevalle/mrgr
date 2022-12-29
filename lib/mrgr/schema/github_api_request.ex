defmodule Mrgr.Schema.GithubAPIRequest do
  use Mrgr.Schema

  schema "github_api_requests" do
    field(:api_call, :string)
    field(:response_code, :integer)
    field(:elapsed_time, :integer)
    field(:data, :map)
    field(:response_headers, :map)

    belongs_to(:installation, Mrgr.Schema.Installation)

    timestamps()
  end

  @create_params ~w[
    api_call
    installation_id
  ]a

  @complete_params ~w[
    response_code
    elapsed_time
    data
    response_headers
  ]a

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @create_params)
    |> foreign_key_constraint(:installation_id)
  end

  def complete_changeset(schema, params) do
    params = handle_data_list(params)

    schema
    |> cast(params, @complete_params)
    |> handle_data_list()
  end

  def ratelimit_reset(request) do
    case request.response_headers["X-RateLimit-Reset"] do
      nil ->
        nil

      ts ->
        {:ok, datetime} = DateTime.from_unix(String.to_integer(ts))
        datetime
    end
  end

  def ratelimit_remaining(request) do
    request.response_headers["X-RateLimit-Remaining"]
  end

  defp handle_data_list(%{data: data} = params) when is_list(data) do
    Map.put(params, :data, %{ein_listen: data})
  end

  defp handle_data_list(params), do: params
end
