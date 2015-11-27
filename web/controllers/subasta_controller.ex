defmodule IascTpSubastas.SubastaController do
  use IascTpSubastas.Web, :controller

  alias IascTpSubastas.Subasta

  plug :scrub_params, "subasta" when action in [:create, :update]

  def index(conn, _params) do
    subastas = Subastero.listar_subastas
    render(conn, "index.json", subastas: subastas)
  end

  def create(conn, %{"subasta" => %{"nombre" => nombre, "precio_base" => precio_base, "duracion" => duracion}}) do
    id_subasta = Subastero.crear_subasta(nombre, precio_base, duracion)
    subasta = Subastero.obtener_subasta(id_subasta)

    if subasta != nil do
      conn
      |> put_status(:created)
      |> render("show.json", subasta: subasta)
    else
      conn
      |> put_status(:unprocessable_entity)
    end
  end

   def show(conn, %{"id" => id}) do
    subasta = Subastero.obtener_subasta(id)
    conn
    |> put_status(:ok)
    |> render("show.json", subasta: subasta)
  end


  # def update(conn, %{"id" => id, "subasta" => subasta_params}) do
  #   subasta = Repo.get!(Subasta, id)
  #   changeset = Subasta.changeset(subasta, subasta_params)

  #   case Repo.update(changeset) do
  #     {:ok, subasta} ->
  #       render(conn, "show.json", subasta: subasta)
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(IascTpSubastas.ChangesetView, "error.json", changeset: changeset)
  #   end
  # end

  # CANCELAR subasta
  def delete(conn, %{"id" => id}) do
    subasta = Subastero.cancelar_subasta(id)

    send_resp(conn, :no_content, "")
  end
end
