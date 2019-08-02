#!/bin/bash

export KLUSTER_LOGS=/kluster/logs
mkdir -p ${KLUSTER_LOGS}
date > ${KLUSTER_LOGS}/time.txt
echo 'Pinging master ...' >> ${KLUSTER_LOGS}/time.txt
export KUBECONFIG=/admin.conf
kubectl get nodes | grep ' Ready    master' > /dev/null
until [ $? -eq 0 ]; do
   echo 'waiting for master 5 seconds'  >> ${KLUSTER_LOGS}/time.txt 
   sleep 5s
   kubectl get nodes | grep ' Ready    master' > /dev/null
done
echo 'Joining cluster...' >> ${KLUSTER_LOGS}/time.txt
source /etc/profile.d/02-k8s.sh
kubeadm config images pull 2>&1  > ${KLUSTER_LOGS}/images-pull.log
kubeadm join --config /kubeadm-join.yaml 2>&1  > ${KLUSTER_LOGS}/kubeadm-join.log
date >> ${KLUSTER_LOGS}/time.txt
