#!/bin/bash
NODE_ID=0
LOGS_DIR=/kafka_logs
SECURITY_PROTOCOL_MAP="CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,EXTERNAL:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL"
LISTENERS="PLAINTEXT://:9092,EXTERNAL://:9093,CONTROLLER://:9094"
CONTROLLER_QUORUM_VOTERS="$NODE_ID@localhost:9094"

# Create a logs directory
mkdir -p $LOGS_DIR/$NODE_ID

KAFKA_VERSION_MAJOR=$(echo $KAFKA_VERSION | cut -d. -f1)
if [ "$KAFKA_VERSION_MAJOR" -ge 4 ]; then
    CONFIG_FOLDER=/opt/kafka/config
else
    CONFIG_FOLDER=/opt/kafka/config/kraft
fi

sed -e "s+^node.id=.*+node.id=$NODE_ID+" \
-e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
-e "s+^listener.security.protocol.map=.*+listener.security.protocol.map=$SECURITY_PROTOCOL_MAP+" \
-e "s+^listeners=.*+listeners=$LISTENERS+" \
-e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
-e "s+^log.dirs=.*+log.dirs=$LOGS_DIR/$NODE_ID+" \
-e "s+^linger.ms=.*+linger.ms=$KAFKA_LINGER_MS+" \
-e "s+^log.retention.ms=.*+log.retention.ms=$KAFKA_LOG_RETENTION_MS+" \
-e "s+^offsets.topic.replication.factor=.*+offsets.topic.replication.factor=$KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR+" \
-e "s+^max.in.flight.requests.per.connection=.*+max.in.flight.requests.per.connection=$KAFKA_MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION+" \
$CONFIG_FOLDER/server.properties > server.properties.updated

mv server.properties.updated $CONFIG_FOLDER/server.properties

CLUSTER_ID=$(kafka-storage.sh random-uuid)

kafka-storage.sh format -t $CLUSTER_ID -c $CONFIG_FOLDER/server.properties

exec kafka-server-start.sh $CONFIG_FOLDER/server.properties
