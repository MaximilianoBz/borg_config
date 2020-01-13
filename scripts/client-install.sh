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

#Descargar borgcron
echo "Instalando script de Lunix: borgcron"
mkdir -p /etc/lunix/borg/
if  [ ! -z ${#CURL} ]; then
    curl -sL https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borgcron?inline=false -o /etc/lunix/borg/borgcron
else
    wget -q https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borgcron?inline=false -O /etc/lunix/borg/borgcron
fi
chmod 600 -R /etc/lunix/borg
chmod +x /etc/lunix/borg/borgcron
echo "Instalando script de Lunix: borgcron logrotate"
if  [ ! -z ${#CURL} ]; then
    curl -sL https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_logrotate?inline=false -o /etc/logrotate.d/borg
else
    wget -q https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_logrotate?inline=false -O /etc/logrotate.d/borg
fi

#Agregar usuario y home de borg
echo "Generando usuario y home para borg"
useradd borg -s /bin/sh -m
if [ ! -d /home/borg/.ssh ]; then mkdir /home/borg/.ssh; fi
chown borg.borg -R /home/borg/.ssh
echo "Instalacion finalizada"