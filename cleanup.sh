#!/bin/bash

footloose delete --config footloose.yaml.k8s.mod

ignite rmi $(ignite images -q)

ignite rmk $(ignite kernel -q)

docker stop $(docker ps -qa)

docker rm $(docker ps -qa)

docker rmi $(docker images -q)



