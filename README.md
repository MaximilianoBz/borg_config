Script para agregar nuevos repositorios en un servidor borgbackup. Genera también el script que se debe copiar al cliente.

Se debe correr desde el servidor.

## Dependencies
- ```borgbackup```

## Instalacion
- Configurar en el script borg_config la variable SERVER con la IP del servidor y la variable DIRBASE con el directorio donde se generaran los repositorios
- Copiar borg_config en /usr/local/sbin/ y hacer ejecutable
- Generar el directorio /etc/lunix/borg y /etc/lunix/borg/.ssh con permisos 600 para root
- Copiar borg_client.conf en /etc/lunix/borg/borg_client.conf
- Generar usuario "borg" y crear la carpeta /home/borg/.ssh (asegurarse que tenga permisos)

## Uso
```
borg_config [--encryption ENCRIPTACION] [--dir DIRECTORIO] [--client CLIENTE]

argumentos opcionales:
   -c | --client              FQDN del cliente (-c cliente.ejemplo.com)
   -e | --encryption          Encriptacion de repositorio (Default: repokey-blake2)
   -d | --dir                 Full path para el repositorio (Default: nombre del cliente dentro de /u/borgbackup/)
   -h | --help                Muestra este mensaje
   -v | --version             Muestra la version del script
```
