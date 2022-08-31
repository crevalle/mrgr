defmodule Mrgr.Schema.WaitingListSignup do
  use Mrgr.Schema

  schema "waiting_list_signups" do
    field(:email, :string)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:email])
    |> validate_required([:email])
    |> downcase_email()
  end

  def downcase_email(cs) do
    case cs.valid? do
      true ->
        email = get_change(cs, :email)
        put_change(cs, :email, String.downcase(email))

      false ->
        cs
    end
  end
end
