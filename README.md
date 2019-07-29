Script para agregar nuevos repositorios en un servidor borgbackup. Genera también el script que se debe copiar al cliente.

Se debe correr desde el servidor.

## Dependencies
- ```borgbackup```

## Instalacion
- Configurar en el script borg_config la variable SERVER con la IP del servidor y la variable DIRBASE con el directorio donde se guardaran los archivos
- Copiar borg_config en /usr/local/sbin/ y hacer ejecutable
- Copiar borg_client en /etc/lunix/borg/borg_client_template
- Generar usuario "borg" y crear la carpeta /home/borg/.ssh (asegurarse que tenga permisos)
- Generar el directorio /etc/lunix/borg con permisos 600 para root

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
