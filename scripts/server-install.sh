#Descarga y configura borg y borg_config en un servidor

#########################
#VARIABLES

#IP o FQDN del servidor
#SERVER="server.example.com"

#Puerto SSH
#PORT=22

#Revisar si esta instalado curl y wget
CURL=$(command -v curl)
WGET=$(command -v wget)
if [ ${#CURL} -eq 0 ] && [ ${#WGET} -eq 0 ]; then
    echo "Instalar curl antes de continuar";
    exit ;
fi

#Instalar borg
#Es necesario al menos la version 1.1 (aqui instalamos descargando el binario)
#En buster se puede instalar por apt, en stretch activando stretch-backports
echo "Instalando borgbackup"
if  [ ! ${#CURL} -eq 0 ]; then
    curl -sL https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64 -o /usr/local/bin/borg
else
    wget -q https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64 -O /usr/local/bin/borg
fi
chown root:root /usr/local/bin/borg
chmod 755 /usr/local/bin/borg

#Descargar borg_config
echo "Instalando script de Lunix: borg_config"
mkdir -p /etc/lunix/borg/.ssh
if  [ ! ${#CURL} -eq 0 ]; then
    curl -sL https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_config?inline=false -o /usr/local/sbin/borg_config
    curl -sL https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borgcron.conf?inline=false -o /etc/lunix/borg/borgcron.conf
else
    wget -q https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_config?inline=false -O /usr/local/sbin/borg_config
    wget -q https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borgcron.conf?inline=false -O /etc/lunix/borg/borgcron.conf
fi
chmod +x /usr/local/sbin/borg_config
chmod 600 -R /etc/lunix/borg

#Agregar usuario y home de borg
echo "Generando usuario y home para borg"
useradd borg -s /bin/sh -m
mkdir /home/borg/.ssh
chown borg.borg -R /home/borg/.ssh