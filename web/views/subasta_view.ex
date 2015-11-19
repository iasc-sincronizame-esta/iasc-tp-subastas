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
      precio: subasta.precio,
      duracion: subasta.duracion}
  end
end
