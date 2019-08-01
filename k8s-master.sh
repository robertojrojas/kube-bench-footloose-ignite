#!/bin/bash

export KLUSTER_LOGS=/kluster/logs
mkdir -p ${KLUSTER_LOGS}
date > ${KLUSTER_LOGS}/time.txt
kubeadm config images pull 2>&1  > ${KLUSTER_LOGS}/images-pull.log
kubeadm init --config /kubeadm.yaml --upload-certs 2>&1 > ${KLUSTER_LOGS}/kubeadm.log
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://git.io/weave-kube-1.6 2>&1 > ${KLUSTER_LOGS}/kubectl-cni.log
date >> ${KLUSTER_LOGS}/time.txt
