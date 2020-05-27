Script para agregar nuevos repositorios en un servidor BorgBackup. Genera también la configuración que se debe copiar al cliente.

Se debe correr desde el servidor.

## Dependencies
- ```borgbackup```

## Instalacion con scripts
La manera más simple de instalarlo, ejecutar los scripts de instalación en el servidor y cliente

- SERVIDOR

```wget -O - https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/scripts/server-install.sh?inline=false | sh```

- CLIENTE

```wget -O - https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/scripts/client-install.sh?inline=false | sh```


## Instalacion manual
- Configurar en el script borg_config la variable SERVER con la IP o FQDN del servidor, la variable PORT con el puerto de conexiones SSH externas y la variable DIRBASE con el directorio donde se generaran los repositorios
- Copiar borg_config en /usr/local/sbin/ y hacer ejecutable
- Generar el directorio /etc/lunix/borg/client y /etc/lunix/borg/client/.ssh con permisos 600 para root
- Copiar borgcron.conf en /etc/lunix/borg/client/borgcron.conf.template
- Generar usuario "borg" y crear la carpeta /home/borg/.ssh

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

Ejecutar borg_config en el servidor para generar la configuración de clientes, y luego seguir las instrucciones para copiar la configuracion en el cliente.
Asegurarse que los clientes lleguen al servidor en el puerto SSH

## borg_tools
Herramienta adicional para facilitar el uso de borg en el cliente. Ofrece varias operaciones mediante un menu o pasando variables

## borg_tools_storage
Similar a borg_tools, pero permite definir sobre que configuracion se quieren realizar las operaciones

## PENDIENTES
- Revisar que script de prune funcione en cron (funciona manualmente)
- Checkeo de backups cada cierto tiempo? borg check y/o borg --dry-run extract 
- Zabbix: Agregar alerta si archivo /etc/lunix/borg_status tiene más de dos días
- Zabbix: Agregar alerta si /etc/lunix/borg_status tiene valor 0