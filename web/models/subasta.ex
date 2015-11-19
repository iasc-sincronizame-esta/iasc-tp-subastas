defmodule IascTpSubastas.Subasta do
  use IascTpSubastas.Web, :model

  schema "subastas" do
    field :titulo, :string
    field :precio, :integer
    field :duracion, :integer

    timestamps
  end

  @required_fields ~w(titulo precio duracion)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
