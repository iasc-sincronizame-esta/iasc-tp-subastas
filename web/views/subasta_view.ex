defmodule IascTpSubastas.SubastaView do
  use IascTpSubastas.Web, :view

  def render("index.json", %{subastas: subastas}) do
    %{data: render_many(Map.to_list(subastas), IascTpSubastas.SubastaView, "subasta.json")}
  end

  def render("show.json", %{subasta: {id_subasta, subasta}}) do
    %{data: render_one({id_subasta, subasta}, IascTpSubastas.SubastaView, "subasta.json")}
  end

  def render("subasta.json", %{subasta: {id_subasta, subasta}}) do
    %{id: id_subasta,
      titulo: subasta.titulo,
      precio: subasta.precio_actual,
      fecha_expiracion: subasta.fecha_expiracion}
  end
end
