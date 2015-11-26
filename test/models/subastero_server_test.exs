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

      Process.alive? unComprador # a él no se le avisó porque fue el que ofertó
    end
  end
end