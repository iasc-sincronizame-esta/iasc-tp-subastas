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
      SubasteroServer.crear_subasta subastero, "Notebook", 999, 60000

      receive do
        { :nueva_subasta, subasta } ->
          assert subasta[:titulo] == "Notebook"
          assert subasta[:precio_actual] == 999
          assert subasta[:fecha_expiracion] != nil
      end
    end

    test "cuando alguien oferta, se le avisa a los demás el nuevo precio" do
      {:ok, subastero} = SubasteroServer.start_link

      unComprador = spawn fn -> receive do end end

      id = SubasteroServer.crear_subasta subastero, "Notebook", 999, 60000
      SubasteroServer.crear_usuario subastero, unComprador, "Un comprador"
      SubasteroServer.crear_usuario subastero, self, "Yo"

      SubasteroServer.ofertar subastero, id, unComprador, 1001

      receive do
        { :nueva_oferta, mensaje } ->
          assert mensaje == "La subasta Notebook tiene un nuevo precio: $ 1001"
      end
    end

    test "cuando alguien oferta con un valor mayor, se le avisa que su oferta fue aceptada" do
      {:ok, subastero} = SubasteroServer.start_link

      parent = self
      unComprador = spawn fn ->
        Process.flag(:trap_exit, true)
        receive do
          {:ok, mensaje} -> send(parent, {:voy_ganando, mensaje})
        end
      end

      id = SubasteroServer.crear_subasta subastero, "Notebook", 999, 60000
      SubasteroServer.crear_usuario subastero, unComprador, "Un comprador"

      SubasteroServer.ofertar subastero, id, unComprador, 1000

      assert_receive {:voy_ganando, "Tu oferta está ganando en Notebook"}
    end

    test "cuando la subasta termina, le avisa al ganador que ganó y al resto que no (adjudicación con competencia)" do
      {:ok, subastero} = SubasteroServer.start_link

      parent = self
      esperarAPerder = fn ->
        Process.flag(:trap_exit, true)
        receive do
          {:subasta_perdida, _} -> send(parent, {:perdi, self()})
        end
      end

      looser1 = spawn_link esperarAPerder
      looser2 = spawn_link esperarAPerder

      SubasteroServer.crear_usuario subastero, looser1, "Perdedor 1"
      SubasteroServer.crear_usuario subastero, looser2, "Perdedor 2"
      SubasteroServer.crear_usuario subastero, self, "Ganador"

      id = SubasteroServer.crear_subasta subastero, "Notebook", 100, 500

      SubasteroServer.ofertar subastero, id, looser1, 200
      SubasteroServer.ofertar subastero, id, looser2, 300
      SubasteroServer.ofertar subastero, id, self, 400

      receive do
        { :subasta_ganada, mensaje } ->
          assert mensaje == "Has ganado la subasta: Notebook!"
      end
      assert_receive {:perdi, looser1}
      assert_receive {:perdi, looser2}
    end

    test "la subasta puede terminar sin ningún ganador" do
      {:ok, subastero} = SubasteroServer.start_link

      SubasteroServer.crear_subasta subastero, "Subasta de 1 milisegundo", 20, 1

      receive do
      after 50 -> end

      subastas = SubasteroServer.listar_subastas subastero
      assert subastas == %{}
    end
  end

  defmodule Escenario3 do
    use ExUnit.Case

    test "cuando se cancela una subasta antes de su expiración y cancelación, nadie gana y todos son notificados" do
      {:ok, subastero} = SubasteroServer.start_link

      parent = self
      unComprador = spawn fn ->
        Process.flag(:trap_exit, true)
        receive do
          {:subasta_cancelada, mensaje} -> send(parent, {:se_cancelo_la_subasta, mensaje})
        end
      end

      id_subasta = SubasteroServer.crear_subasta subastero, "Notebook", 999, 60000
      SubasteroServer.crear_usuario subastero, unComprador, "Comprador 1"
      SubasteroServer.crear_usuario subastero, self, "Yo"

      SubasteroServer.ofertar subastero, id_subasta, self, 1000
      SubasteroServer.ofertar subastero, id_subasta, unComprador, 1001

      SubasteroServer.cancelar_subasta subastero, id_subasta

      receive do
        { :subasta_cancelada, mensaje } ->
          assert mensaje == "La subasta ha sido cancelada: Notebook"
      end
      assert_receive {:se_cancelo_la_subasta, "La subasta ha sido cancelada: Notebook"}
    end
  end

  defmodule Escenario4 do
    use ExUnit.Case

    test "un usuario que se registra luego de creada una subasta, puede ofertar y ganar" do
      {:ok, subastero} = SubasteroServer.start_link
      unComprador = spawn fn -> receive do end end

      SubasteroServer.crear_usuario subastero, unComprador, "Comprador 1"
      id_subasta = SubasteroServer.crear_subasta subastero, "Notebook", 999, 500
      SubasteroServer.crear_usuario subastero, self, "Yo"

      SubasteroServer.ofertar subastero, id_subasta, unComprador, 1000
      SubasteroServer.ofertar subastero, id_subasta, self, 1001

      receive do
        { :subasta_ganada, mensaje } ->
          assert mensaje == "Has ganado la subasta: Notebook!"
      end
    end
  end

  defmodule Escenario5 do
    use ExUnit.Case

    test "puede haber varias subastas funcionando simultáneamente" do
      {:ok, subastero} = SubasteroServer.start_link
      unComprador = spawn fn -> receive do end end

      SubasteroServer.crear_usuario subastero, unComprador, "Comprador 1"
      subasta_notebook = SubasteroServer.crear_subasta subastero, "Notebook", 999, 300
      subasta_campera = SubasteroServer.crear_subasta subastero, "Campera de cuero para romper la noche", 200, 500
      SubasteroServer.crear_usuario subastero, self, "Yo"

      SubasteroServer.ofertar subastero, subasta_notebook, self, 1001
      SubasteroServer.ofertar subastero, subasta_campera, self, 300

      receive do
        { :subasta_ganada, mensaje } ->
          assert mensaje == "Has ganado la subasta: Notebook!"
      end

      receive do
        { :subasta_ganada, mensaje } ->
          assert mensaje == "Has ganado la subasta: Campera de cuero para romper la noche!"
      end
    end
  end

  defmodule Pruebas do
    use ExUnit.Case
    use Timex

    test "probando la biblioteca timex" do
      now = Date.now
      IO.inspect now
      IO.inspect (now |> Date.add(Time.to_timestamp(2998, :msecs)))
      # el valor del medio está en segundos
      # ¿pasar la duración a segundos?
    end
  end

  # # ISO a día
  # date = "2015-06-24T04:50:34-05:00"
  # date |> DateFormat.parse("{ISO}")

  # # Día a ISOz (para guardar en mongo)
  # Date.local |> DateFormat.format("{ISOz}")
  # {:ok, "2015-06-24T05:04:13.910Z"}
end