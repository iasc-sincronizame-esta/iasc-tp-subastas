defmodule IascTpSubastas.SubastaTest do
  use IascTpSubastas.ModelCase

  alias IascTpSubastas.Subasta

  @valid_attrs %{duracion: 42, precio: 42, titulo: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Subasta.changeset(%Subasta{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Subasta.changeset(%Subasta{}, @invalid_attrs)
    refute changeset.valid?
  end
end
