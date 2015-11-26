defmodule SubasteroServerTest do
  use ExUnit.Case

  defmodule Escenario1 do
    use ExUnit.Case

    test "inicialmente no hay subastas" do
      {:ok, subastero} = SubasteroServer.start_link

      subastas = SubasteroServer.listar_subastas subastero
      assert subastas = %{}
    end

    test "al publicar una subasta, le avisa a los compradores" do
      {:ok, subastero} = SubasteroServer.start_link

      recibirNotificacion = fn ->
        receive do
          { :nueva_subasta, _ } ->
        end
      end

      compradorA = spawn recibirNotificacion
      compradorB = spawn recibirNotificacion
      SubasteroServer.crear_usuario subastero, compradorA, "Juan"
      SubasteroServer.crear_usuario subastero, compradorB, "Perez"

      SubasteroServer.crear_subasta subastero, self, "TP de IASC", 999, 60000

      assert not Process.alive? compradorA
      assert not Process.alive? compradorB
    end
  end
end