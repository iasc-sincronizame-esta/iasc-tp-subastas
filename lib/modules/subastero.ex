require Integer

defmodule Subastero do
  def start() do
    subastas = %{}
    compradores = %{}
    spawn fn -> loop({ subastas, compradores }) end
  end

  def notificar(interesados, mensaje, get_pid \\ fn(interesado) -> interesado[:pid] end) do
    Enum.each(interesados, fn(interesado) -> send get_pid.(interesado), mensaje end)
  end

  def loop({subastas, compradores}) do
    receive do
      { :crear_usuario, pid_usuario, nombre } ->

        id_usuario =  :random.uniform(1000000)

        datos_comprador =
          %{
            pid: pid_usuario,
            nombre: nombre
          }

        compradores = Map.put(compradores, id_usuario, datos_comprador)

        IO.puts "ATENCIÓN! TENEMOS UN NUEVO USUARIO: #{nombre}"

      { :crear_subasta, pid_vendedor, titulo, precio_base, duracion } ->

        id_subasta =  :random.uniform(1000000)
        datos_subasta =
          %{
            pid_vendedor: pid_vendedor,
            titulo: titulo,
            precio_base: precio_base,
            duracion: duracion,
            compradores: HashSet.new
          }
        subastas = Map.put(subastas, id_subasta, datos_subasta)

        notificar(Map.values(compradores), { :nueva_subasta, datos_subasta} )

        IO.puts "ATENCIÓN! TENEMOS UNA NUEVA SUBASTA: #{titulo}"

      { :ofertar, id_subasta, pid_comprador, oferta } ->

        subasta = Map.get(subastas, id_subasta)

        if oferta > subasta[:precio_base] do

          Map.put(subasta, :compradores, Set.put(subasta[:compradores], pid_comprador))

          subastas = Map.put(subastas, id_subasta,
            %{
              pid_vendedor: subasta[:pid_vendedor],
              titulo: subasta[:titulo],
              precio_base: oferta,
              duracion: subasta[:duracion],
              pid_comprador: pid_comprador,
              compradores: subasta[:compradores]
           }
          )

          notificar([%{pid: pid_comprador}], { :ok, "Tu oferta esta primero en #{subasta[:titulo]}!"})

          diferencia = HashSet.new
          diferencia = Set.put(diferencia, pid_comprador)

          notificar(Map.values(Set.difference(subasta[:compradores], diferencia)),
            { :nueva_oferta, "Hubo una nueva oferta en: #{subasta[:titulo]} de $ #{oferta}"})

          IO.puts "ATENCION: La nueva oferta fue realizada con exito"

        else
          notificar([%{pid: pid_comprador}], {:ok, "Tu oferta fue insuficiente"})
        end
      { :listar_subastas, pid_usuario } ->
        notificar([%{pid:  pid_usuario }], {:ok, subastas})

    end
    loop({ subastas, compradores })
  end
end