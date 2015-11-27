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

## Configuración
```bash
mix deps.get
mix ecto.create
# tener mongodb en localhost:27017
# sudo hostname localhost
# (para cambiar temporalmente el hostname)
```

## Correr el servidor
```bash
make server
```

## Correr un cliente
```
make client
```

## Correr los tests
```
make test
```

## Ejemplo de phoenix.gen
```
mix phoenix.gen.json Subasta subastas titulo:string precio:integer duracion:integer
```