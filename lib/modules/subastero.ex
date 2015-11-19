require Integer

defmodule Subastero do
  
  def start() do
  	subastas = %{}
  	compradores = %{}
    usuarios = %{}
    spawn fn -> loop({ subastas }) end
  end

  #Esto asume que cada interesado tiene un pid para ser notificado
  def notificar(interesados, mensaje) do
  	Enum.each(interesados, fn {pid_interesado, _ } -> send pid_interesado, mensaje end)
  end

  def loop({ subastas, compradores, usuarios }) do
    receive do

	  { :crear_usuario, pid_usuario, nombre } ->

	    id_usuario = make_ref

	    datos_usuario =       
    		%{
      			pid_vendedor: pid_usuario,
      			nombre: nombre
  			}
      	
      	usuarios = Map.put(usuarios, id_usuario, datos_usuarios) 

      	IO.puts "ATENCIÓN! TENEMOS UN NUEVO USUARIO: #{nombre}"

      { :crear_subasta, pid_vendedor, titulo, precio_base, duracion } ->
      	
      	id_subasta = make_ref
      	datos_subasta =       		
      		%{
      			pid_vendedor: pid_vendedor, 
      			titulo: titulo, 
      			precio_base: precio_base, 
      			duracion: duracion,
      			compradores: HashSet.new
  			}
      	subastas = Map.put(subastas, id_subasta, datos_subasta)  

		notificar(compradores, { :nueva_subasta, datos_subasta} )

      	IO.puts "ATENCIÓN! TENEMOS UNA NUEVA SUBASTA: #{titulo}"
 
      { :cancelar_subasta, pid_vendedor, id_subasta } ->

        subasta_a_cancelar = Map.get(subastas, id_subasta)

      	notificar(compradores, { :subasta_cancelada, "La subasta ha sido cancelada: #{subasta_a_cancelar[:titulo]}"})

      	subastas = Map.delete(subastas, id_subasta)

      	IO.puts "ATENCIÓN! SE HA CERRADO UNA SUBASTA: #{subasta_a_cancelar[:titulo]}"

      { :ofertar, id_subasta, pid_comprador, oferta } ->

  		subasta = Map.get(subastas, id_subasta)

      	if oferta > subasta[:precio_base] do
      	    		
      		subasta[:compradores] = Set.put(subasta[:compradores], pid_comprador)
      	
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

  			notificar([pid_comprador], { :ok, "Tu oferta esta primero en #{subasta[:titulo]}!"})

  			diferenia = HashSet.new
  			diferencia = Set.put(diferencia, pid_comprador)

  			notificar(Set.difference(subasta[:compradores], diferencia), 
  				{ :nueva_oferta, "Hubo una nueva oferta en: #{subasta[:titulo]} de $ #{oferta}"})

  			IO.puts "ATENCION: La nueva oferta fue realizada con exito"

		else 
			notificar([pid_comprador], {:ok, "Tu oferta fue insuficiente"})
		end

	  { :listar_subastas, pid_usuario } -> 

	  	notificar([pid_usuario], {:ok, subastas})



    loop({ subastas, compradores, usuarios })
  
  end

end