defmodule ClientServer do
  def start(nombre, nodo, pid) do
    rname = :"#{nombre}"
    registrar_nombre = fn()->
      :global.register_name(rname, pid)
    end
    Node.spawn(nodo, registrar_nombre)
    IO.puts "Nombre global registrado"
    # Subastero.crear_usuario(rname, nombre)
    IO.puts "http://127.0.0.1:4000/subastas"

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