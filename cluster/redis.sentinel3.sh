#!/bin/bash
##################################################
#                                                #
#           Redis Sentinel 6.0.4                 #
#                                                #
##################################################

# Configuración de puertos
REDIS_PORT="26379"
firewall-cmd --permanent --add-port=$REDIS_PORT/tcp
firewall-cmd --reload

# Variables utilizadas
REDIS_PORT="26379" # Puerto por el que se expondra Redis
REDIS_CONTAINER="redis.sentinel3" # Nombre del Contenedor
REDIS_IP="10.142.0.2" # Ip del servidor donde sera desplegada esta instancia de Redis y por el que las otras instancias pueden llegar a el
REDIS_PASSWORD="sentinel3kevopspwd" # Password de esta instancia de Redis
REDIS_MASTER_ALIAS="redis.master.kevops" # Alias asociado al redis master
REDIS_MASTER_IP="10.128.0.9" # Ip del Redis Master
REDIS_MASTER_PORT="6379" # Puerto por donde se anuncia el Redis Master
REDIS_SENTINEL_QUORUM="2" # Cantidad de sentinel que deberan estar de acuerdo para promover a un esclavo
REDIS_MASTER_PASSWORD="masterkevopspwd" # Password del Redis Master

mkdir -p /var/containers/$REDIS_CONTAINER/etc/redis

cat<<-EOF > /var/containers/$REDIS_CONTAINER/etc/redis/redis.conf
protected-mode no
port $REDIS_PORT
sentinel announce-ip $REDIS_IP
sentinel announce-port $REDIS_PORT
sentinel monitor $REDIS_MASTER_ALIAS $REDIS_MASTER_IP $REDIS_MASTER_PORT $REDIS_SENTINEL_QUORUM
sentinel auth-pass $REDIS_MASTER_ALIAS $REDIS_MASTER_PASSWORD
requirepass $REDIS_PASSWORD
EOF

chown 999:0 -R /var/containers/$REDIS_CONTAINER

docker run -itd --name  $REDIS_CONTAINER \
    -p $REDIS_PORT:$REDIS_PORT \
    --restart unless-stopped \
    -v /etc/localtime:/etc/localtime:ro \
    -v /var/containers/$REDIS_CONTAINER/etc/redis:/etc/redis:z \
    -e TZ=America/Mexico_City \
    redis:6.0.4 redis-sentinel /etc/redis/redis.conf