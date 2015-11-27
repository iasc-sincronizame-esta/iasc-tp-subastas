defmodule SubasteroServerTest do
  use ExUnit.Case

  setup do
    SubastasHome.clean {:global, GlobalSubastasHome}
    CompradoresHome.clean {:global, GlobalCompradoresHome}
  end

  test "inicialmente no hay subastas" do
    {:ok, subastero} = SubasteroServer.start_link

    subastas = SubasteroServer.listar_subastas subastero
    assert subastas == []
  end

  test "al publicar una subasta, le avisa a los compradores" do
    {:ok, subastero} = SubasteroServer.start_link

    :global.register_name Yo, self
    SubasteroServer.crear_usuario subastero, Yo, "Yo"
    SubasteroServer.crear_subasta subastero, "Notebook", 999, 60000

    receive do
      { :nueva_subasta, subasta } ->
        assert subasta[:titulo] == "Notebook"
        assert subasta[:precio_actual] == 999
        assert subasta[:fecha_expiracion] != nil
    end

    :global.unregister_name Yo
  end

  test "cuando alguien oferta, se le avisa a los demás el nuevo precio" do
    {:ok, subastero} = SubasteroServer.start_link

    unComprador = spawn fn -> receive do end end
    :global.register_name UnCompradorasd, unComprador
    :global.register_name Yo, self

    id = SubasteroServer.crear_subasta subastero, "Notebook", 999, 60000
    id_unComprador = SubasteroServer.crear_usuario subastero, UnCompradorasd, "Un comprador"
    SubasteroServer.crear_usuario subastero, Yo, "Yo"

    SubasteroServer.ofertar subastero, id, id_unComprador, 1001

    receive do
      { :nueva_oferta, mensaje } ->
        assert mensaje == "La subasta Notebook tiene un nuevo precio: $ 1001"
    end

    :global.unregister_name UnCompradorasd
    :global.unregister_name Yo
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
    :global.register_name UnComprador, unComprador

    id = SubasteroServer.crear_subasta subastero, "Notebook", 999, 60000
    id_unComprador = SubasteroServer.crear_usuario subastero, UnComprador, "Un comprador"

    SubasteroServer.ofertar subastero, id, id_unComprador, 1000

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
    :global.register_name Looser1, looser1
    :global.register_name Looser2, looser2
    :global.register_name Yo, self

    id_looser1 = SubasteroServer.crear_usuario subastero, Looser1, "Perdedor 1"
    id_looser2 = SubasteroServer.crear_usuario subastero, Looser2, "Perdedor 2"
    id_ganador = SubasteroServer.crear_usuario subastero, Yo, "Ganador"

    id = SubasteroServer.crear_subasta subastero, "Notebook", 100, 500

    SubasteroServer.ofertar subastero, id, id_looser1, 200
    SubasteroServer.ofertar subastero, id, id_looser2, 300
    SubasteroServer.ofertar subastero, id, id_ganador, 400

    receive do
      { :subasta_ganada, mensaje } ->
        assert mensaje == "Has ganado la subasta: Notebook!"
    end
    assert_receive {:perdi, looser1}
    assert_receive {:perdi, looser2}

    :global.unregister_name Yo
  end

  test "la subasta puede terminar sin ningún ganador" do
    {:ok, subastero} = SubasteroServer.start_link

    SubasteroServer.crear_subasta subastero, "Subasta de 1 milisegundo", 20, 1

    receive do
    after 50 -> end

    subastas = SubasteroServer.listar_subastas subastero
    assert subastas == []
  end

  test "cuando se cancela una subasta antes de su expiración y cancelación, nadie gana y todos son notificados" do
    {:ok, subastero} = SubasteroServer.start_link

    parent = self
    unComprador = spawn fn ->
      Process.flag(:trap_exit, true)
      receive do
        {:subasta_cancelada, mensaje} -> send(parent, {:se_cancelo_la_subasta, mensaje})
      end
    end
    :global.register_name UnComprador, unComprador
    :global.register_name Yo, self

    id_subasta = SubasteroServer.crear_subasta subastero, "Notebook", 999, 60000
    id_unComprador = SubasteroServer.crear_usuario subastero, UnComprador, "Comprador 1"
    id_yo = SubasteroServer.crear_usuario subastero, Yo, "Yo"

    SubasteroServer.ofertar subastero, id_subasta, id_yo, 1000
    SubasteroServer.ofertar subastero, id_subasta, id_unComprador, 1001

    SubasteroServer.cancelar_subasta subastero, id_subasta

    receive do
      { :subasta_cancelada, mensaje } ->
        assert mensaje == "La subasta ha sido cancelada: Notebook"
    end
    assert_receive {:se_cancelo_la_subasta, "La subasta ha sido cancelada: Notebook"}

    :global.unregister_name Yo
  end

  test "un usuario que se registra luego de creada una subasta, puede ofertar y ganar" do
    {:ok, subastero} = SubasteroServer.start_link
    unComprador = spawn fn -> receive do end end
    :global.register_name UnComprador, unComprador
    :global.register_name Yo, self

    id_unComprador = SubasteroServer.crear_usuario subastero, UnComprador, "Comprador 1"
    id_subasta = SubasteroServer.crear_subasta subastero, "Notebook", 999, 500
    id_yo = SubasteroServer.crear_usuario subastero, Yo, "Yo"

    SubasteroServer.ofertar subastero, id_subasta, id_unComprador, 1000
    SubasteroServer.ofertar subastero, id_subasta, id_yo, 1001

    receive do
      { :subasta_ganada, mensaje } ->
        assert mensaje == "Has ganado la subasta: Notebook!"
    end

    :global.unregister_name UnComprador
    :global.unregister_name Yo
  end

  test "puede haber varias subastas funcionando simultáneamente" do
    {:ok, subastero} = SubasteroServer.start_link
    unComprador = spawn fn -> receive do end end
    :global.register_name UnComprador, unComprador
    :global.register_name Yo, self

    SubasteroServer.crear_usuario subastero, UnComprador, "Comprador 1"
    subasta_notebook = SubasteroServer.crear_subasta subastero, "Notebook", 999, 300
    subasta_campera = SubasteroServer.crear_subasta subastero, "Campera de cuero para romper la noche", 200, 500
    id_yo = SubasteroServer.crear_usuario subastero, Yo, "Yo"

    SubasteroServer.ofertar subastero, subasta_notebook, id_yo, 1001
    SubasteroServer.ofertar subastero, subasta_campera, id_yo, 300

    receive do
      { :subasta_ganada, mensaje } ->
        assert mensaje == "Has ganado la subasta: Notebook!"
    end

    receive do
      { :subasta_ganada, mensaje } ->
        assert mensaje == "Has ganado la subasta: Campera de cuero para romper la noche!"
    end

    :global.unregister_name UnComprador
    :global.unregister_name Yo
  end
end