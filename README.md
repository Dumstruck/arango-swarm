
# ArangoDB Cluster in Docker Swarm

This is an example of how to run ArangoDB in cluster mode in Docker Swarm with
properly configurable scaling with `docker service scale`. Other methods I've
seen online scale by duplicating the yaml which is a total antipattern in
Docker Swarm.

This requires a custom image of ArangoDB that has the Docker socket bind-mounted. The image's
entrypoint uses Docker to dynamically dicover the other ArangoDB process in the swarm and set the
proper run paramters to arangod's entrypoint.

The custom image also has an example of how to
deterministically populate the database in a consistent manner
on start up. This is important to ensure that document `_key`s match
between dbservers. A naive approach would try to populate each
dbserver after starting up.


Deploy your arango swarm with

```
docker stack deploy -c stack.yml arango
```

You should then see three services via `docker service`:

```
mqcyxvd864n6 arango_agent       replicated 3/3 dumstruck/arangodb *:8529->8529/tcp
z619h8xdq31g arango_dbserver    replicated 3/3 dumstruck/arangodb *:8529->8529/tcp
rle4e6z48gdo arango_coordinator replicated 3/3 dumstruck/arangodb *:8529->8529/tcp
```

And you can scale each of these services indpendently with 

```
docker scale arango_agent=6 arango_dbserver=9 arango_coordinator=9
```

However, you'll want to take into consideration that the persistence for the dbserver
is a docker volume, so you'll likely want to restrict each physical node to a single dbserver
with swarm label run constraints. 
