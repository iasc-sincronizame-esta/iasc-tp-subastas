defmodule DateHelper do
	use Timex

	def ahora_mas(milisegundos) do
		ahora = Date.now
		ahora |> Date.add(Time.to_timestamp(milisegundos, :msecs))
	end 
end