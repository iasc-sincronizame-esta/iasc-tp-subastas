# IascTpSubastas

## Cosas importantes
- El código nuestro está en:
```
/lib
/lib/modules
/web/controllers/subasta_controller.ex
/web/models/subasta.ex
/test/models
```

## Instalar
```bash
mix deps.get
mix ecto.create
# instalar mongodb
```

## Correr el servidor
```bash
make server
```

## Correr los tests
```
MIX_ENV=test mix ecto.drop ; mix test
```

## Ejemplo de phoenix.gen
mix phoenix.gen.json Subasta subastas titulo:string precio:integer duracion:integer
