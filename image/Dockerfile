#\|/----------------------\|/#
#
#         BUILDER image
#
#/|\----------------------/|\#

FROM arangodb/arangodb:latest as builder

# Install latest node (v13+) so we don't need babel
RUN apk add --update --no-cache --upgrade nodejs-current npm curl

ADD ./init/ /init

WORKDIR /init

# run.sh runs arangod in the background, installs node deps
# and imports the data to the arango instance
RUN sh /init/run.sh

#\|/----------------------\|/#
#
#          MAIN image
#
#/|\----------------------/|\#

FROM arangodb/arangodb:latest

# Need jq and docker for cluster-entrypoint.sh to work
RUN apk update && \
	apk add --no-cache docker jq

ADD ./init.js /docker-entrypoint-initdb.d/init.js

# Grab our collection dumps from builder, place in dumps folder
COPY --from=builder /init/dump/ /docker-entrypoint-initdb.d/dumps/_system

ADD ./cluster-entrypoint.sh /

RUN chmod +x /cluster-entrypoint.sh

ENTRYPOINT ["/cluster-entrypoint.sh"]

EXPOSE 8529

CMD ["arangod"]

