#!/bin/bash
##################################################
#                                                #
#             Redis Esclavo 6.0.4                #
#                                                #
##################################################

# Configuración de puertos
REDIS_PORT="6379"
firewall-cmd --permanent --add-port=$REDIS_PORT/tcp
firewall-cmd --reload

# Variables utilizadas
REDIS_PORT="6379" # Puerto por el que se expondra Redis
REDIS_CONTAINER="redis.esclavo" # Nombre del Contenedor
REDIS_IP="10.142.0.2" # Ip del servidor donde sera desplegada esta instancia de Redis y por el que las otras instancias pueden llegar a el
REDIS_PASSWORD="esclavokevopspwd" # Password de esta instancia de Redis
REDIS_MASTER_IP="10.128.0.9" # Ip del Redis Master
REDIS_MASTER_PORT="6379" # Puerto por donde se anuncia el Redis Master
REDIS_TCP_BACKLOG="511" # Cantidad de solicitudes que seran atendidas por segundo
REDIS_MASTER_PASSWORD="masterkevopspwd" # Password del Redis Master

# Configuración de memoria
echo never > /sys/kernel/mm/transparent_hugepage/enabled
sysctl -w net.core.somaxconn=$REDIS_TCP_BACKLOG
sysctl vm.overcommit_memory=2

# Configuración Redis
mkdir -p /var/containers/$REDIS_CONTAINER{/etc/redis,/var/lib/redis}

cat<<-EOF > /var/containers/$REDIS_CONTAINER/etc/redis/redis.conf
protected-mode no
port $REDIS_PORT
dir /var/lib/redis
appendonly yes
appendfilename "redis.appendonly.aof"
requirepass $REDIS_PASSWORD
replica-announce-ip $REDIS_IP
replica-announce-port $REDIS_PORT
tcp-backlog $REDIS_TCP_BACKLOG
replicaof $REDIS_MASTER_IP $REDIS_MASTER_PORT
masterauth $REDIS_MASTER_PASSWORD
replica-priority 1
timeout 0
tcp-keepalive 300
daemonize no
supervised no
pidfile /var/run/redis_6379.pid
loglevel notice
databases 50
always-show-logo yes
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
rdb-del-sync-files no
replica-serve-stale-data no
replica-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-diskless-load disabled
repl-timeout 120
repl-disable-tcp-nodelay no
acllog-max-len 128
maxclients 10000
maxmemory 2147483648
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
lazyfree-lazy-user-del no
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
stream-node-max-bytes 4096
stream-node-max-entries 100
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
dynamic-hz yes
aof-rewrite-incremental-fsync yes
rdb-save-incremental-fsync yes
jemalloc-bg-thread yes
EOF

chown 999:0 -R /var/containers/$REDIS_CONTAINER

docker run -itd --name  $REDIS_CONTAINER \
    -p $REDIS_PORT:$REDIS_PORT \
    --memory-swappiness=0 \
    --restart unless-stopped \
    --sysctl net.core.somaxconn=$REDIS_TCP_BACKLOG \
    -v /etc/localtime:/etc/localtime:ro \
    -v /var/containers/$REDIS_CONTAINER/etc/redis:/etc/redis:z \
    -v /var/containers/$REDIS_CONTAINER/var/lib/redis:/var/lib/redis:z \
    -e TZ=America/Mexico_City \
    redis:6.0.4 redis-server /etc/redis/redis.conf