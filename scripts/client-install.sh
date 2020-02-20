#Descarga y configura borg y borg_config en un servidor

#Revisar si esta instalado curl o wget
CURL=$(command -v curl)
WGET=$(command -v wget)
if [ ! $CURL ] && [ ! $WGET ]; then
    echo "Instalar curl antes de continuar";
    echo "Como descargaste este script?";
    exit ;
fi

#Instalar borg
#Es necesario al menos la version 1.1 (aqui instalamos descargando el binario)
#En buster se puede instalar por apt, en stretch activando stretch-backports
echo "Instalando borgbackup"
if  [ $CURL ]; then
    curl -sL https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64 -o /usr/local/bin/borg
else
    wget -q https://github.com/borgbackup/borg/releases/download/1.1.10/borg-linux64 -O /usr/local/bin/borg
fi
chown root:root /usr/local/bin/borg
chmod 755 /usr/local/bin/borg

#Descargar borgcron
echo "Instalando script de Lunix: borgcron"
mkdir -p /etc/lunix/borg/
if  [ $CURL ]; then
    curl -sL https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borgcron?inline=false -o /etc/lunix/borg/borgcron
else
    wget -q https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borgcron?inline=false -O /etc/lunix/borg/borgcron
fi
chmod 600 -R /etc/lunix/borg
chmod +x /etc/lunix/borg/borgcron
echo "Instalando script de Lunix: borgcron logrotate"
if  [ $CURL ]; then
    curl -sL https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_logrotate?inline=false -o /etc/logrotate.d/borg
else
    wget -q https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_logrotate?inline=false -O /etc/logrotate.d/borg
fi

#Descargar borg_tools
if  [ $CURL ]; then
    curl -sL https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_tools?inline=false -o /usr/local/sbin/borg_tools
else
    wget -q https://gitlab.lunix.com.ar/pramos/borg_config/raw/master/borg_tools?inline=false -O /usr/local/sbin/borg_tools
fi
chmod +x /usr/local/sbin/borg_tools

#Carpeta para logs
mkdir /var/log/borg
#Cron
echo "Agregando cron"
touch /var/spool/cron/crontabs/root
echo "" >> /var/spool/cron/crontabs/root
echo "#Borg Backup" >> /var/spool/cron/crontabs/root
echo "30 23 * * * /etc/lunix/borg/borgcron" >> /var/spool/cron/crontabs/root

echo "Instalacion finalizada"