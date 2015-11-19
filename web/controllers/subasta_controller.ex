defmodule IascTpSubastas.SubastaController do
  use IascTpSubastas.Web, :controller

  alias IascTpSubastas.Subasta

  plug :scrub_params, "subasta" when action in [:create, :update]

  def index(conn, _params) do
    subastas = Repo.all(Subasta)
    render(conn, "index.json", subastas: subastas)
  end

  def create(conn, %{"subasta" => subasta_params}) do
    changeset = Subasta.changeset(%Subasta{}, subasta_params)

    case Repo.insert(changeset) do
      {:ok, subasta} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", subasta_path(conn, :show, subasta))
        |> render("show.json", subasta: subasta)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(IascTpSubastas.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    subasta = Repo.get!(Subasta, id)
    render(conn, "show.json", subasta: subasta)
  end

  def update(conn, %{"id" => id, "subasta" => subasta_params}) do
    subasta = Repo.get!(Subasta, id)
    changeset = Subasta.changeset(subasta, subasta_params)

    case Repo.update(changeset) do
      {:ok, subasta} ->
        render(conn, "show.json", subasta: subasta)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(IascTpSubastas.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    subasta = Repo.get!(Subasta, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(subasta)

    send_resp(conn, :no_content, "")
  end

  # ---
  # Custom
  # ---

  def ofertar(conn, %{"id" => id, "oferta" => oferta}) do
    subasta = Repo.get!(Subasta, id)

    precio = oferta["precio"]
    nombre = oferta["nombre"]

    cambio = %{
      "precio" => precio,
      "interesados" => subasta.interesados ++ [nombre],
      "ganador_actual" => nombre 
    }
    changeset = Subasta.changeset(subasta, cambio)

    case Repo.update(changeset) do
      {:ok, subasta} ->
        conn
        |> send_resp(201, "")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(IascTpSubastas.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
