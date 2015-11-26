require Integer

defmodule SubastasHome do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def start(opts \\ []) do
    GenServer.start(__MODULE__, :ok, opts)
  end

  # ---

  def get_all(server) do
    GenServer.call server, { :get_all }
  end

  def get(server, id_subasta) do
    GenServer.call server, { :get, id_subasta }
  end

  def upsert(server, id_subasta, datos_subasta) do
    GenServer.cast server, { :upsert, id_subasta, datos_subasta }
  end

  def delete(server, id_subasta) do
    GenServer.cast server, { :delete, id_subasta }
  end

  # ---------- Callbacks ------------

  def init(:ok) do
    mapa = %{}
    { :ok, mapa }
  end

  def handle_call({ :get_all }, _from, mapa) do
    { :reply, mapa, mapa }
  end

  def handle_call({ :get, id_subasta }, _from, mapa) do
    { :reply, Map.get(mapa, id_subasta), mapa }
  end

  def handle_cast({ :upsert, id_subasta, datos_subasta }, mapa) do
    { :noreply, Map.put(mapa, id_subasta, datos_subasta) }
  end

  def handle_cast({ :delete, id_subasta }, mapa) do
    { :noreply, Map.delete(mapa, id_subasta) }
  end
end