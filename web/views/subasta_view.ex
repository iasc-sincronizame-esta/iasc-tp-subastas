defmodule IascTpSubastas.SubastaView do
  use IascTpSubastas.Web, :view

  def render("index.json", %{subastas: subastas}) do
    %{data: render_many(subastas, IascTpSubastas.SubastaView, "subasta.json")}
  end

  def render("show.json", %{subasta: subasta}) do
    %{data: render_one(subasta, IascTpSubastas.SubastaView, "subasta.json")}
  end

  def render("subasta.json", %{subasta: subasta}) do
    %{id: subasta.id,
      titulo: subasta.titulo,
      precio: subasta.precio_actual,
      fecha_expiracion: subasta.fecha_expiracion}
  end

  def render("oferta.json", %{oferta: {id_oferta}}) do
    id_oferta
  end

  def render("comprador.json", %{comprador: {id_comprador}}) do
    id_comprador
  end
end
