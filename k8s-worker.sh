#!/bin/bash

export KLUSTER_LOGS=/kluster/logs
mkdir -p ${KLUSTER_LOGS}
date > ${KLUSTER_LOGS}/time.txt
echo 'Sleeping ...' >> ${KLUSTER_LOGS}/time.txt
sleep 5m
echo 'Continue...' >> ${KLUSTER_LOGS}/time.txt
source /etc/profile.d/02-k8s.sh
kubeadm config images pull 2>&1  > ${KLUSTER_LOGS}/images-pull.log
kubeadm join --config /kubeadm-join.yaml 2>&1  > ${KLUSTER_LOGS}/kubeadm-join.log
date >> ${KLUSTER_LOGS}/time.txt
