defmodule IascTpSubastas.CompradorController do
  use IascTpSubastas.Web, :controller

  alias IascTpSubastas.Comprador

  plug :scrub_params, "comprador" when action in [:create]

  def index(conn, _params) do
    subastas = Subastero.listar_subastas
    render(conn, "index.json", subastas: subastas)
  end

  def create(conn, %{"comprador" => comprador}) do
    result = Subastero.crear_usuario(self, comprador)

    IO.puts "comprador creado: #{result}"

    if result != nil do
      conn
      |> put_status(:created)
      |> render("comprador.json", comprador: {result})
    else
      conn
      |> put_status(:unprocessable_entity)
    end
  end

end
