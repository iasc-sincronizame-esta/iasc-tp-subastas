defmodule ControladorSubasta do
	def empezar_subasta(pid, id_subasta, duracion) do
		receive do
		after duracion ->
			terminar_subasta(pid, id_subasta)
		end
	end	

	def terminar_subasta(pid, id_subasta) do
		GenServer.call pid, {:terminar_subasta, id_subasta} 
	end

end
