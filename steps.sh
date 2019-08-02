#!/bin/bash

# Need to be running as root
# Due to Firecracker requirements this install requires Virtualization support
# In my case, I'm running on a laptop - bare metal
apt-get update && sudo apt-get install -y cpu-checker
kvm-ok
#INFO: /dev/kvm exists
#KVM acceleration can be used

# Install dependencies
apt-get update && apt-get install -y --no-install-recommends dmsetup openssh-client git binutils

# Install Docker https://docs.docker.com/install/linux/docker-ce/ubuntu/

# Install Go https://golang.org/dl/
tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz
export PATH=/usr/local/go/bin:$PATH

# Install ignite
export VERSION=v0.4.2
curl -fLo ignite https://github.com/weaveworks/ignite/releases/download/${VERSION}/ignite
chmod +x ignite
sudo mv ignite /usr/local/bin

# Install footloose
# At the time of this recording the latest footloose release does not support Ignite
# The master branch of the github repository does contain the required code, so
# we'll install it from source.
# This requires Go v1.12+ to be installed on your system
git clone https://github.com/weaveworks/footloose
cd footloose
go build
mv footloose /usr/local/bin
cd ..

# Install kubectl
wget https://storage.googleapis.com/kubernetes-release/release/v1.15.1/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin

# Get  kube-bench-footloose-ignite
git clone https://github.com/robertojrojas/kube-bench-footloose-ignite
cd kube-bench-footloose-ignite

## Prepare cluster files
./prepare.sh

# Build kluster Docker image
# This image is a workaround to provide the ability to inject custom scripts into the VMs
cd kluster
docker build -t robertojrojas/ignite-kubeadm:kluster-v1 .
cd ..

## View the footloose config
#vi footloose.yaml.k8s

sed "s,<ABSOLUTE_PATH>,$(pwd),g" footloose.yaml.k8s > footloose.yaml.k8s.mod

# make sure DNS is setup correctly.
# You might need to add the following to /etc/hosts
# 172.17.0.2 firekube.luxas.dev
#ping firekube.luxas.dev

## create cluster vms
footloose --config footloose.yaml.k8s.mod create


# This is needed to route requests to k8s
docker run -d -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg -p 6443:443 haproxy:alpine

# Troubleshooting
#ignite ssh -i ./cluster-key cluster-master0
#ignite ps -a

#docker ps -a

#docker images

# 3-5 mins
export KUBECONFIG=$(pwd)/run/admin.conf
#kubectl get nodes

# 5+ mins worker should be online
#kubectl get pod

kubectl get nodes | grep ' Ready    <none>' > /dev/null
until [ $? -eq 0 ]; do
   echo 'waiting for worker to be ready...'
   sleep 5s
   kubectl get nodes | grep ' Ready    <none>' > /dev/null
done

# Execute the kube-bench on a worker node.
kubectl apply -f job-worker.yaml

echo "wait for job to execute..."
sleep 10s
# Take a look at the kube-bench output
kubectl logs $(kubectl get pod --no-headers | grep kube | awk '{print $1}')


