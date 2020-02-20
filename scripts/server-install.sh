#Descarga y configura borg y borg_config en un servidor

#Revisar si esta instalado curl o wget
CURL=$(command -v curl)
WGET=$(command -v wget)
if [ -z ${#CURL} ] && [ -z ${#WGET} ]; then
    echo "Instalar curl antes de continuar";
    echo "Como descargaste este script?";
    exit ;
fi

#Instalar borg
#Es necesario al menos la version 1.1 (aqui instalamos descargando el binario)
#En buster se puede instalar por apt, en stretch activando stretch-backports
echo "Instalando borgbackup"
if  [ ! -z ${#CURL} ]; then
    curl -sL https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64 -o /usr/local/bin/borg
else
    wget -q https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64 -O /usr/local/bin/borg
fi
chown root:root /usr/local/bin/borg
chmod 755 /usr/local/bin/borg

#Descargar borg_config
echo "Instalando script de Lunix: borg_config"
mkdir -p /etc/lunix/borg/client/.ssh
if  [ ! -z ${#CURL} ]; then
    curl -sL https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_config?inline=false -o /usr/local/sbin/borg_config
    curl -sL https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borgcron.conf.template?inline=false -o /etc/lunix/borg/client/borgcron.conf.template
else
    wget -q https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_config?inline=false -O /usr/local/sbin/borg_config
    wget -q https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borgcron.conf.template?inline=false -O /etc/lunix/borg/client/borgcron.conf.template
fi
chmod +x /usr/local/sbin/borg_config
chmod 600 -R /etc/lunix/borg

#Descargar borg_tools y borgcron-prune
if  [ ! -z ${#CURL} ]; then
    curl -sL https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_tools_storage?inline=false -o /usr/local/sbin/borg_tools_storage
    curl -sL https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borgcron-prune-server?inline=false -o /etc/lunix/borg/borgcron-prune
else
    wget -q https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_tools_storage?inline=false -O /usr/local/sbin/borg_tools_storage
    wget -q https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borgcron-prune-server?inline=false -O /etc/lunix/borg/borgcron-prune
fi
chmod +x /usr/local/sbin/borg_tools_storage
chmod +x /etc/lunix/borg/borgcron-prune

#Generar carpeta para repositorio
if [ ! -d /u/borgbackup/ ]; then
    mkdir -p /u/borgbackup/;
fi

#Agregar usuario y home de borg
echo "Generando usuario y home para borg"
useradd borg -s /bin/sh -m
if [ ! -d /home/borg/.ssh ]; then mkdir /home/borg/.ssh; fi
chown borg.borg -R /home/borg/.ssh
chown borg.borg -R /u/borgbackup/
echo "Instalacion finalizada"
echo "Configurar las variables SERVER y PORT en /usr/local/sbin/borg_config"