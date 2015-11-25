require Integer

defmodule SubasteroServer do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def start(opts \\ []) do
    GenServer.start(__MODULE__, :ok, opts)
  end

  def crear_usuario(server, pid_usuario, nombre) do
    GenServer.call server, { :crear_usuario, pid_usuario, nombre }
  end

  def crear_subasta(server, pid_vendedor, titulo, precio_base, duracion) do
    GenServer.call server, { :crear_subasta, pid_vendedor, titulo, precio_base, duracion }
  end

  def ofertar(server, id_subasta, pid_comprador, oferta) do
    GenServer.call server, { :ofertar, id_subasta, pid_comprador, oferta }
  end

  def listar_subastas(server, pid_usuario) do
    GenServer.call server, { :listar_subastas, pid_usuario }
  end

  # -----

  def notificar(interesados, mensaje, get_pid \\ fn(interesado) -> interesado[:pid] end) do
    Enum.each(interesados, fn(interesado) -> send get_pid.(interesado), mensaje end)
  end

  # ---------- Callbacks ------------

  def init(:ok) do
    subastas = %{}
    compradores = %{}
    # spawn fn -> loop({ subastas, compradores }) end
    {:ok, {subastas, compradores}}
  end

  def handle_call({ :crear_usuario, pid_usuario, nombre }, _from,  { subastas, compradores }) do
    id_usuario =  :random.uniform(1000000)

    datos_comprador =
      %{
        pid: pid_usuario,
        nombre: nombre
      }

    compradores = Map.put(compradores, id_usuario, datos_comprador)

    IO.puts "ATENCIÓN! TENEMOS UN NUEVO USUARIO: #{nombre}"

    {:reply, :ok, { subastas, compradores } }
  end

  def handle_call({ :crear_subasta, pid_vendedor, titulo, precio_base, duracion }, _from, { subastas, compradores }) do
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

    {:reply, :ok, { subastas, compradores } }
  end

  def handle_call({ :ofertar, id_subasta, pid_comprador, oferta }, _from, { subastas, compradores }) do
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

      compradores_a_notificar = Enum.reject(subasta[:compradores], fn(pid) -> pid == pid_comprador end)

      notificar(Enum.map(compradores_a_notificar, fn(comprador) -> Map.values(comprador) end),
        { :nueva_oferta, "Hubo una nueva oferta en: #{subasta[:titulo]} de $ #{oferta}"})

      IO.puts "ATENCION: La nueva oferta fue realizada con exito"

    else
      notificar([%{pid: pid_comprador}], {:ok, "Tu oferta fue insuficiente"})
    end

    {:reply, :ok, { subastas, compradores } }
  end

  def handle_call({ :listar_subastas, pid_usuario }, _from, { subastas, compradores }) do
    notificar([%{pid:  pid_usuario }], {:ok, subastas})
    {:reply, :ok, { subastas, compradores } }
  end
end