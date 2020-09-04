#!/usr/bin/env bash

arangod &

until $(curl --output /dev/null --fail "http://localhost:8529"); do
	printf '.'
	sleep 5
done

# Do what you need to initialize the database
#node src/index.js

# Dump the databases you need
# This will be automatically embedded into the image
# And then restored when the image dbserver boots up
arangodump --server.password '' \
	--collection foo \
	--collection bar \
	--collection baz

