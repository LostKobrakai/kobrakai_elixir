defmodule KobrakaiWeb.OneToManyForm.GroceriesList do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:email, :string)

    embeds_many :lines, Line, on_replace: :delete do
      field(:item, :string)
      field(:amount, :integer)
      field(:delete, :boolean, virtual: true)
    end
  end

  def changeset(form, params) do
    form
    |> cast(params, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> cast_embed(:lines, with: &line_changeset/2)
  end

  def line_changeset(list, params) do
    changeset =
      list
      |> cast(params, [:item, :amount, :delete])
      |> validate_required([:item, :amount])

    if get_change(changeset, :delete) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end
end
