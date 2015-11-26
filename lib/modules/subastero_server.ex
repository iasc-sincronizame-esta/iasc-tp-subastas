require Integer
require SubastasHome

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

  def cancelar_subasta(server, id_subasta) do
    GenServer.call server, { :cancelar_subasta, id_subasta }
  end

  def listar_subastas(server) do
    GenServer.call server, { :listar_subastas }
  end

  # -----

  def notificar(interesados, mensaje, get_pid \\ fn(interesado) -> interesado[:pid] end) do
    Enum.each(interesados, fn(interesado) -> send get_pid.(interesado), mensaje end)
  end

  # ---------- Callbacks ------------

  def init(:ok) do
    IO.puts "El subastero ha sido iniciado"
    
    { _, subastasHome } = SubastasHome.start_link
    compradores = %{}
    {:ok, {subastasHome, compradores}}
  end

  ###
  ### CREAR USUARIO
  ###
  def handle_call({ :crear_usuario, pid_usuario, nombre }, _from,  { subastasHome, compradores }) do
    id_usuario =  :random.uniform(1000000)

    datos_comprador =
      %{
        pid: pid_usuario,
        nombre: nombre
      }

    compradores = Map.put(compradores, id_usuario, datos_comprador)

    IO.puts "ATENCIÓN! TENEMOS UN NUEVO USUARIO: #{nombre}"

    {:reply, :ok, { subastasHome, compradores } }
  end

  ###
  ### CREAR SUBASTA
  ###
  def handle_call({ :crear_subasta, pid_vendedor, titulo, precio_base, duracion }, _from, { subastasHome, compradores }) do
    id_subasta =  :random.uniform(1000000)
    datos_subasta =
      %{
        pid_vendedor: pid_vendedor,
        titulo: titulo,
        precio_base: precio_base,
        duracion: duracion,
        compradores: HashSet.new
      }

    SubastasHome.upsert subastasHome, id_subasta, datos_subasta

    notificar(Map.values(compradores), { :nueva_subasta, datos_subasta} )

    IO.puts "ATENCIÓN! TENEMOS UNA NUEVA SUBASTA: #{titulo}"

    {:reply, :ok, { subastasHome, compradores } }
  end

  ###
  ### OFERTAR
  ###
  def handle_call({ :ofertar, id_subasta, pid_comprador, oferta }, _from, { subastasHome, compradores }) do
    subasta = SubastasHome.get subastasHome, id_subasta

    if oferta > subasta[:precio_base] do

      subasta = Map.put(subasta, :compradores, Set.put(subasta[:compradores], pid_comprador))

      SubastasHome.upsert(subastasHome, id_subasta,
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

      IO.puts "ATENCIÓN: La nueva oferta fue realizada con exito"

    else
      notificar([%{pid: pid_comprador}], {:ok, "Tu oferta fue insuficiente"})
    end

    {:reply, :ok, { subastasHome, compradores } }
  end

  def handle_call({ :cancelar_subasta, id_subasta}, _from, { subastas, compradores }) do

    subasta_a_cancelar = Map.get(subastas, id_subasta)

    notificar(subasta_a_cancelar[:compradores], 
      { :subasta_cancelada, "La subasta ha sido cancelada: #{subasta_a_cancelar[:titulo]}"},
      fn(comprador) -> comprador end)

    subastas = Map.delete(subastas, id_subasta)

    IO.puts "ATENCIÓN! SE HA CERRADO UNA SUBASTA: #{subasta_a_cancelar[:titulo]}"

    {:reply, :ok, { subastas, compradores } }

  end

  def handle_call({ :listar_subastas }, _from, { subastasHome, compradores }) do
    subastas = SubastasHome.get_all subastasHome
    {:reply, {:ok, subastas}, { subastasHome, compradores } }
  end

end