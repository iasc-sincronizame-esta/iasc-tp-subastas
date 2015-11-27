defmodule ClientServer do
  def start(nombre, nodo, pid) do
    server = System.get_env "server"
    rname = :"#{nombre}"
    :global.register_name(rname, pid)
    crear_usuario = fn()->
      Subastero.crear_usuario(:Aldana, "#{nombre}")
    end
    Node.spawn(:"server@aldanaqm", crear_usuario)
    IO.puts "Connected. Listenning..."

    listen(nodo, pid)
  end

  def listen(nodo, pid) do
    receive do
      {:nueva_subasta, titulo} -> IO.puts titulo
      _ -> IO.puts "No entiendo el mensaje"
    end

    listen(nodo, pid)
  end
end