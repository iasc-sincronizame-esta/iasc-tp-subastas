require Integer
require SubastasHome
require ControladorSubasta

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

  def terminar_subasta(server, id_subasta) do
    GenServer.call server, { :terminar_subasta, id_subasta }
  end

  # ---

  def notificar(interesados, mensaje, get_pid \\ fn(interesado) -> interesado[:pid] end) do
    Enum.each(interesados, fn(interesado) -> send get_pid.(interesado), mensaje end)
  end

  # ---------- Callbacks ------------

  def init(:ok) do
    IO.puts "El subastero ha sido iniciado"
    
    { _, subastasHome } = SubastasHome.start_link
    compradores = %{}
    controladores = %{}
    {:ok, {subastasHome, compradores, controladores}}
  end

  ###
  ### CREAR USUARIO
  ###
  def handle_call({ :crear_usuario, pid_usuario, nombre }, _from,  { subastasHome, compradores, controladores}) do
    id_usuario =  :random.uniform(1000000)

    datos_comprador =
      %{
        pid: pid_usuario,
        nombre: nombre
      }

    compradores = Map.put(compradores, id_usuario, datos_comprador)

    IO.puts "ATENCIÓN! TENEMOS UN NUEVO USUARIO: #{nombre}"

    {:reply, :ok, { subastasHome, compradores, controladores} }
  end

  ###
  ### CREAR SUBASTA
  ###
  def handle_call({ :crear_subasta, pid_vendedor, titulo, precio_base, duracion }, _from, { subastasHome, compradores, controladores}) do
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

    pid_controlador = crear_controlador_subasta(id_subasta, duracion)

    controladores = Map.put(controladores, id_subasta, pid_controlador)

    IO.puts "ATENCIÓN! TENEMOS UNA NUEVA SUBASTA: #{titulo}"

    {:reply, :ok, { subastasHome, compradores, controladores } }
  end

  def crear_controlador_subasta(id_subasta, duracion) do
    parent = self
    spawn fn -> ControladorSubasta.empezar_subasta(parent, id_subasta, duracion) end
  end

  ###
  ### OFERTAR
  ###
  def handle_call({ :ofertar, id_subasta, pid_comprador, oferta }, _from, { subastasHome, compradores, controladores }) do
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

      notificar([%{pid: pid_comprador}], { :ok, "Tu oferta está ganando en #{subasta[:titulo]}"})

      compradores_a_notificar = Enum.reject(subasta[:compradores], fn(pid) -> pid == pid_comprador end)

      notificar(Enum.map(compradores_a_notificar, fn(comprador) -> Map.values(comprador) end),
        { :nueva_oferta, "La subasta #{subasta[:titulo]} tiene un nuevo precio: $ #{oferta}"})

      IO.puts "ATENCIÓN! UN USUARIO OFERTÓ EN #{subasta[:titulo]} por $ #{oferta}"
    else
      notificar([%{pid: pid_comprador}], {:ok, "Tu oferta fue insuficiente"})
      IO.puts "ATENCIÓN! UN USUARIO OFERTÓ EN #{subasta[:titulo]} pero fue insuficiente"
    end

    {:reply, :ok, { subastasHome, compradores, controladores } }
  end

  ###
  ### CANCELAR SUBASTA
  ###
  def handle_call({ :cancelar_subasta, id_subasta}, _from, { subastasHome, compradores, controladores }) do
    matar_controlador(controladores, id_subasta)

    subasta_a_cancelar = SubastasHome.get subastasHome, id_subasta

    notificar(subasta_a_cancelar[:compradores], 
      { :subasta_cancelada, "La subasta ha sido cancelada: #{subasta_a_cancelar[:titulo]}"},
      fn(comprador) -> comprador end)

    SubastasHome.delete(subastasHome, id_subasta)

    IO.puts "ATENCIÓN! SE HA CANCELADO UNA SUBASTA: #{subasta_a_cancelar[:titulo]}"

    {:reply, :ok, { subastasHome, compradores, controladores } }

  end

  def handle_call({ :listar_subastas }, _from, { subastasHome, compradores, controladores }) do
    subastas = SubastasHome.get_all subastasHome
    {:reply, {:ok, subastas}, { subastasHome, compradores, controladores } }
  end

  def handle_call({ :terminar_subasta, id_subasta }, _from, { subastasHome, compradores, controladores }) do
    
    IO.puts "ATENCIÓN! TERMINÓ LA SUBASTA #{id_subasta}"

    subasta = SubastasHome.get subastasHome, id_subasta

    IO.inspect subasta 

    pid_comprador = subasta[:pid_comprador]

    if pid_comprador != nil do 
      notificar([pid_comprador], 
        { :subasta_terminada, "Has ganado la subasta: #{subasta[:titulo]}!"},
        fn(comprador) -> comprador end)
    end

    perdedores_a_notificar = Enum.reject(subasta[:compradores], fn(pid) -> pid == pid_comprador end)

    notificar(Enum.map(perdedores_a_notificar, fn(comprador) -> Map.values(comprador) end),
      { :subasta_terminada, "La subasta ha finalizado y has perdido: #{subasta[:titulo]}"})

    SubastasHome.delete subastasHome, id_subasta

    IO.puts "ATENCIÓN! La subasta #{subasta[:titulo]} terminó con éxito por #{subasta[:precio_base]}"

    {:reply, :ok, { subastasHome, compradores, controladores } }
  end

  # ---------- Helpers ------------

  def matar_controlador(controladores, id_subasta) do
    controlador = Map.get(controladores, id_subasta)
    Process.exit(controlador, :kill)
  end
end