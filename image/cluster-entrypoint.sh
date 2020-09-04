#!/bin/sh

set -e

args=""
myRole="$ARANGO_CLUSTER_ROLE"

if [ -z "$myRole" ]; then
	echo >&2 'error: ARANGO_CLUSTER_ROLE is not set'
	echo >&2 '  You need to specify ARANGO_CLUSTER_ROLE as either AGENT, COORDINATOR, or DBSERVER'
	exit 1
fi

if [ ! -S "/var/run/docker.sock" ]; then
	echo >&2 'error: /var/run/docker.sock is not available'
	echo >&2 '  Please mount /var/run/docker.sock from the host'
	exit 1
fi

myId=`cat /etc/hostname`
myConfig=`docker container inspect $myId | jq -r '.[].Config'`
myServiceName=`echo $myConfig | jq -r '.Labels["com.docker.swarm.service.name"]'`
myTaskName=`echo $myConfig | jq -r '.Labels["com.docker.swarm.task.name"]'`

if [ "$myTaskName" != "null" ]; then
	args="$args --cluster.my-address tcp://$myTaskName:8529"
else
	echo >&2 'WARNING: Could not determine --cluster.my-address from container labels'
	echo >&2 '  This is likely because the container was not created by swarm manager as a service task'
	#exit 1
fi


case $myRole in
	agent)
		numReplicas=`docker service inspect $myServiceName | jq -r '.[].Spec.Mode.Replicated.Replicas'`
		args="$args --agency.activate true"
		args="$args --agency.my-address tcp://$myTaskName:8529"
		args="$args --agency.supervision true"
		args="$args --agency.size $numReplicas"
		;;
	dbserver)
		args="$args --cluster.my-role DBSERVER"
		;;
	coordinator)
		args="$args --cluster.my-role COORDINATOR"
		;;
esac

export ARANGO_NO_AUTH=1

peers=`docker ps --format='{{.Image}} {{.ID}}' | grep flyvana/arango | cut -f2 -d' '`

for peer in $peers; do
	peerConfig=`docker container inspect $peer | jq '.[].Config'`
	peerTaskName=`echo $peerConfig | jq -r '.Labels["com.docker.swarm.task.name"]'`
	# TODO throw error if no taskname?
	peerRole=`echo $peerConfig | jq -r '.Env[]' | grep ARANGO_CLUSTER_ROLE | cut -d= -f2`
	case $peerRole in
		agent)
			if [ $myRole == 'agent' ]; then
				args="$args --agency.endpoint tcp://$peerTaskName:8529"
			else
				args="$args --cluster.agency-endpoint tcp://$peerTaskName:8529"
			fi
			;;
		dbserver)
			;;
		coordinator)
			;;
	esac
done

#sed -i /entrypoint.sh -e "s;set -e;set -ex;"

# `sh` escape hatch
if [ "$@" == "sh" ]; then
	exec sh
fi

exec /entrypoint.sh arangod $args


