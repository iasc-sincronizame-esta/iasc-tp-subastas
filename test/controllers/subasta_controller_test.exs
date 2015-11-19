defmodule IascTpSubastas.SubastaControllerTest do
  use IascTpSubastas.ConnCase

  alias IascTpSubastas.Subasta
  @valid_attrs %{duracion: 42, precio: 42, titulo: "some content"}
  @invalid_attrs %{}

  setup do
    conn = conn() |> put_req_header("accept", "application/json")
    {:ok, conn: conn}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, subasta_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    subasta = Repo.insert! %Subasta{}
    conn = get conn, subasta_path(conn, :show, subasta)
    assert json_response(conn, 200)["data"] == %{"id" => subasta.id,
      "titulo" => subasta.titulo,
      "precio" => subasta.precio,
      "duracion" => subasta.duracion}
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_raise Ecto.NoResultsError, fn ->
      get conn, subasta_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, subasta_path(conn, :create), subasta: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Subasta, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, subasta_path(conn, :create), subasta: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    subasta = Repo.insert! %Subasta{}
    conn = put conn, subasta_path(conn, :update, subasta), subasta: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Subasta, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    subasta = Repo.insert! %Subasta{}
    conn = put conn, subasta_path(conn, :update, subasta), subasta: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    subasta = Repo.insert! %Subasta{}
    conn = delete conn, subasta_path(conn, :delete, subasta)
    assert response(conn, 204)
    refute Repo.get(Subasta, subasta.id)
  end
end
