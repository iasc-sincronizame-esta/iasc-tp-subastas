defmodule SubasteroServerTest do
  use ExUnit.Case

  defmodule Escenario1 do
    use ExUnit.Case

    test "inicialmente no hay subastas" do
      {:ok, subastero} = SubasteroServer.start_link

      subastas = SubasteroServer.listar_subastas subastero
      assert subastas == %{}
    end

    test "al publicar una subasta, le avisa a los compradores" do
      {:ok, subastero} = SubasteroServer.start_link

      SubasteroServer.crear_usuario subastero, self, "Yo"
      SubasteroServer.crear_subasta subastero, self, "Notebook", 999, 60000

      receive do
        { :nueva_subasta, subasta } ->
          assert subasta[:titulo] == "Notebook"
          assert subasta[:precio_base] == 999
      end
    end

    test "cuando alguien oferta, se le avisa a los demás el nuevo precio" do
      {:ok, subastero} = SubasteroServer.start_link

      unComprador = spawn fn -> receive do end end

      id = SubasteroServer.crear_subasta subastero, self, "Notebook", 999, 60000
      SubasteroServer.crear_usuario subastero, unComprador, "Un comprador"
      SubasteroServer.crear_usuario subastero, self, "Yo"

      SubasteroServer.ofertar subastero, id, self, 1000
      SubasteroServer.ofertar subastero, id, unComprador, 1001
      
      receive do
        { :nueva_oferta, mensaje } ->
          assert mensaje == "La subasta Notebook tiene un nuevo precio: $ 1001"
      end

      assert Process.alive? unComprador # a él no se le avisó porque fue el que ofertó
    end

    test "cuando la subasta termina, le avisa al ganador y a los perdedores" do
      {:ok, subastero} = SubasteroServer.start_link

      looser1 = spawn &SubasteroServerTest.esperarAPerder/0
      looser2 = spawn &SubasteroServerTest.esperarAPerder/0
      SubasteroServer.crear_usuario subastero, looser1, "Perdedor 1"
      SubasteroServer.crear_usuario subastero, looser2, "Perdedor 2"
      SubasteroServer.crear_usuario subastero, self, "Ganador"
      
      id = SubasteroServer.crear_subasta subastero, self, "Notebook", 100, 1000
      
      SubasteroServer.ofertar subastero, id, looser1, 200
      SubasteroServer.ofertar subastero, id, looser2, 300
      SubasteroServer.ofertar subastero, id, self, 400
      
      receive do
        { :subasta_ganada, mensaje } ->
          assert mensaje == "Has ganado la subasta: Notebook!"
      end
      assert not Process.alive? looser1
      assert not Process.alive? looser2
    end
  end

  def esperarAPerder() do
    receive do
      { :subasta_perdida, _ } ->
      _ -> SubasteroServerTest.esperarAPerder()
    end
  end
end