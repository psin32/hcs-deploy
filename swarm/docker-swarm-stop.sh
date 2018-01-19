#!/bin/bash

docker service rm hcs-catalog

docker service rm hcs-users

docker service rm hcs-zuul

docker service rm hcs-eureka

docker service rm db-users

docker service rm data-setup

docker service rm mongo3

docker service rm mongo2

docker service rm mongo1

docker service rm hcs-ui

docker service rm kafka-connect

docker service rm schema-registry

docker service rm kafka

docker service rm zookeeper

docker network rm commerce


