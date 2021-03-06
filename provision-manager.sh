#!/bin/bash

set -e

# map manager ip address
MANAGER_IP=$1
SHARED_FOLDER=/home/core/share

# check shared folder exsits
if [ ! -d "$SHARED_FOLDER" ]; then
	echo ERROR: $SHARED_FOLDER does not exists.
    exit 1 # terminate and indicate error
fi

# check if docker is running
if [ "`systemctl is-active docker-tls-tcp.socket`" != "active" ]; then
	echo ERROR: 'docker-tls-tcp.socket' is not running.
    exit 1 # terminate and indicate error
fi

# create swarm
docker swarm init --listen-addr ${MANAGER_IP}:2377 --advertise-addr ${MANAGER_IP}
# save tokens
docker swarm join-token -q worker > ${SHARED_FOLDER}/worker_token
docker swarm join-token -q manager > ${SHARED_FOLDER}/manager_token
# create networks
docker network create --driver overlay --attachable mesos
docker network create --driver overlay --attachable proxy
# use stack to create infrastructure
docker stack deploy -c ${SHARED_FOLDER}/kombinat.yml kombinat
# this is a hack
bash -c 'sleep 5m; docker service update --force kombinat_traefik' &

