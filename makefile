server:
	type=server iex --sname server --cookie subastas -S mix phoenix.server
client:
	type=client server=server@aldanaqm nick=aldana iex --sname client --cookie subastas -S mix run
tests:
	mix test
drop_db:
	mongo iasc_tp_subastas_dev --eval "db.dropDatabase()"