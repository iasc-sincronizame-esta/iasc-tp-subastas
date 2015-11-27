defmodule ClientServer do
  def start(nombre, nodo, pid) do
    server = System.get_env "server"
    rname = :"#{nombre}"
    :global.register_name(rname, pid)
    crear_usuario = fn()->
      Subastero.crear_usuario(rname, "#{nombre}")
    end
    Node.spawn(:"server@aldanaqm", crear_usuario)
    IO.puts "Connected. Listenning..."

    listen(nodo, pid)
  end

  def listen(nodo, pid) do
    receive do
      {:nueva_subasta, datos_subasta} -> IO.inspect datos_subasta
      _ -> IO.puts "No entiendo el mensaje"
    end

    listen(nodo, pid)
  end
end