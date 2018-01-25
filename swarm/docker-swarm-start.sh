#!/bin/bash

echo "Creating network with name commerce"

docker network create --driver overlay commerce

echo "Create service for mongodb 1st instance"
docker service create --replicas 1 --network commerce --name mongo1 --detach=true -p 27017:27017 mongo mongod --replSet commercers

echo "Create service for mongodb 2nd instance"
docker service create --replicas 1 --network commerce --name mongo2 --detach=true -p 27018:27017 mongo mongod --replSet commercers

echo "Create service for mongodb 3rd instance"
docker service create --replicas 1 --network commerce --name mongo3 --detach=true -p 27019:27017 mongo mongod --replSet commercers

echo "Create service for mysql database"
docker service create --replicas 1 --network commerce --name db-users --detach=false -p 3306 -e MYSQL_ROOT_PASSWORD=root -e MYSQL_USER=mysqluser -e MYSQL_PASSWORD=mysqlpw psingh4321/users-db

echo "Setting up replica set for mongo db, also setting up test data for catalog application"
docker service create --replicas 1 --network commerce --restart-max-attempts 5 --name data-setup --detach=false -e MONGO1=mongo1 -e MONGO2=mongo2 -e MONGO3=mongo3 -e RS=commercers psingh4321/hcs-data-setup

echo "Create service for service registry (HCS-EUREKA)"
docker service create --replicas 1 --network commerce --name hcs-eureka --detach=false -p 8001:8001 psingh4321/hcs-eureka

echo "Create service for API gateway (HCS-ZUUL)"
docker service create --replicas 1 --network commerce --name hcs-zuul --detach=true -p 8000:8000 psingh4321/hcs-zuul

echo "Create service for HCS-USER application"
docker service create --replicas 2 --network commerce --name hcs-users --detach=true -p 8080 --constraint=node.role==manager psingh4321/hcs-users

echo "Create service for HCS-CATALOG application"
docker service create --replicas 2 --network commerce --name hcs-catalog --detach=true -p 8090 psingh4321/hcs-catalog

echo "Create service for HCS-ORDER application"
docker service create --replicas 2 --network commerce --name hcs-order --detach=true -p 8060 psingh4321/hcs-order:1.0

echo "Create service for HCS-PAYMENT application"
docker service create --replicas 2 --network commerce --name hcs-payment --detach=true -p 8050 psingh4321/hcs-payment:1.0

echo "Create service for HCS-UI application"
docker service create --replicas 2 --network commerce --name hcs-ui --detach=true -p 80:5000 psingh4321/hcs-ui:1.0

echo "Create service for HCS-ADMIN-UI application"
docker service create --replicas 2 --network commerce --name hcs-admin-ui --detach=true -p 81:5001 psingh4321/hcs-admin-ui

echo "Create service for zookeeper"
docker service create --replicas 1 --network commerce --name zookeeper --detach=false \
    -p 2181 \
    -e ZOOKEEPER_CLIENT_PORT=2181 \
    -e ZOOKEEPER_TICK_TIME=2000 \
    confluentinc/cp-zookeeper:4.0.0

echo "Create service for kafka"
docker service create --replicas 1 --network commerce --name kafka --detach=false -p 9092 \
    --hostname kafka \
    -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
    -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092 \
    -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
    confluentinc/cp-kafka:4.0.0

echo "Create service for schema-registry"
docker service create --replicas 1 --network commerce --name schema-registry --detach=false -p 8081 \
  --hostname schema-registry \
  -e SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL=zookeeper:2181 \
  -e SCHEMA_REGISTRY_HOST_NAME=schema-registry \
  -e SCHEMA_REGISTRY_LISTENERS=http://schema-registry:8081 \
  confluentinc/cp-schema-registry:4.0.0


echo "Create service for kafka-connect"
docker service create --replicas 1 --network commerce --name kafka-connect --detach=false -p 8083:8083 \
  --hostname kafka-connect \
  -e CONNECT_BOOTSTRAP_SERVERS=kafka:9092 \
  -e CONNECT_REST_PORT=8083 \
  -e CONNECT_GROUP_ID="quickstart-avro" \
  -e CONNECT_CONFIG_STORAGE_TOPIC="quickstart-avro-config" \
  -e CONNECT_OFFSET_STORAGE_TOPIC="quickstart-avro-offsets" \
  -e CONNECT_STATUS_STORAGE_TOPIC="quickstart-avro-status" \
  -e CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR=1 \
  -e CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR=1 \
  -e CONNECT_STATUS_STORAGE_REPLICATION_FACTOR=1 \
  -e CONNECT_KEY_CONVERTER="io.confluent.connect.avro.AvroConverter" \
  -e CONNECT_VALUE_CONVERTER="io.confluent.connect.avro.AvroConverter" \
  -e CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL="http://schema-registry:8081" \
  -e CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL="http://schema-registry:8081" \
  -e CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_REST_ADVERTISED_HOST_NAME="kafka-connect" \
  -e CONNECT_LOG4J_ROOT_LOGLEVEL=INFO \
  --constraint=node.role==manager psingh4321/hcs-kafka-connect


