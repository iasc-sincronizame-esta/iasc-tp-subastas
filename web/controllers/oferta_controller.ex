defmodule IascTpSubastas.OfertaController do
  use IascTpSubastas.Web, :controller

  alias IascTpSubastas.Oferta

  plug :scrub_params, "oferta" when action in [:create]

  def create(conn, %{"id_subasta" => id_subasta, "id_comprador" => id_comprador, "oferta" => oferta}) do
    # {id_subasta, _} = Integer.parse(id_subasta)
    # {id_comprador, _} = Integer.parse(id_comprador)
    # {oferta, _} = Integer.parse(oferta)

    result = Subastero.ofertar(id_subasta, id_comprador, oferta)

    if oferta != nil do
      conn
      |> put_status(:created)
      |> render("oferta.json", oferta: {result})
    else
      conn
      |> put_status(:unprocessable_entity)
    end
  end
end
