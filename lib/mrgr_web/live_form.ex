defmodule MrgrWeb.Form do
  defstruct [:action, :changeset]

  def new do
  end

  def create(changeset) do
    %__MODULE__{
      action: :create,
      changeset: changeset
    }
  end

  def edit(changeset) do
    %__MODULE__{
      action: :edit,
      changeset: changeset
    }
  end

  def update_changeset(form, changeset) do
    %{form | changeset: changeset}
  end

  def creating?(%{action: :create}), do: true
  def creating?(_form), do: false

  def editing?(%{action: :edit}), do: true
  def editing?(_form), do: false

  def object(%{changeset: %{data: obj}}), do: obj
end
