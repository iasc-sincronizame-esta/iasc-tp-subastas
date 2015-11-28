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

Instrucciones
-------------

Correr los siguientes comandos en orden

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
## Correr el servidor de failover
```
make failover
```
## Correr un cliente
```
make client
```
## Correr un segundo cliente
```
make client2
```
## Correr un tercer cliente
```
make client3
```
## Correr los tests
```
make tests
```

## Ejemplo de phoenix.gen
```
mix phoenix.gen.json Subasta subastas titulo:string precio:integer duracion:integer
```