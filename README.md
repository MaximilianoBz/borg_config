Script para agregar nuevos repositorios en un servidor borgbackup. Genera también el script que se debe copiar al cliente.

Se debe correr desde el servidor.

## Dependencies
- ```borgbackup```

## Instalacion
- Copiar borg_config en /usr/local/sbin/ y hacer ejecutable
- Copiar borg_client en /etc/lunix/borg_client_template
- Generar usuario "borg" y crear la carpeta /home/borg/.ssh (asegurarse que tenga permisos)
