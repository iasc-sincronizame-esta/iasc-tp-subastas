server:
	type=server iex --sname server --cookie subastas -S mix phoenix.server
client:
	type=client server=server@aldanaqm nick=Aldana iex --sname client --cookie subastas -S mix run --eval "ClientServer.start('Aldana', Node.self, self)"
	# ClientServer.nuevo_cliente(cs, "Aldana", Node.self, self)
client2:
	type=client server=server@aldanaqm nick=aldana iex --sname client2 --cookie subastas -S mix run
tests:
	mix test
drop_db:
	mongo iasc_tp_subastas_dev --eval "db.dropDatabase()"