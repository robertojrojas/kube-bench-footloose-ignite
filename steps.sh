#!/bin/bash

mkdir work && cd work

# Install dependencies
apt-get update && apt-get install -y --no-install-recommends dmsetup openssh-client git binutils

apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get install -y docker-ce docker-ce-cli containerd.io


export GO_VERSION=1.12.9
wget -c https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz -O - | tar -C /usr/local  -xz
export PATH=/usr/local/go/bin:$PATH

# Install ignite
export IGNITE_VERSION=v0.5.1
export GOARCH=$(go env GOARCH 2>/dev/null || echo "amd64")

for binary in ignite ignited; do
    echo "Installing ${binary}..."
    curl -sfLo ${binary} https://github.com/weaveworks/ignite/releases/download/${IGNITE_VERSION}/${binary}-${GOARCH}
    chmod +x ${binary}
    sudo mv ${binary} /usr/local/bin
done


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
wget https://storage.googleapis.com/kubernetes-release/release/v1.15.2/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin

# Get  kube-bench-footloose-ignite
#git clone https://github.com/robertojrojas/kube-bench-footloose-ignite
#cd kube-bench-footloose-ignite

## Prepare cluster files
wget https://raw.githubusercontent.com/robertojrojas/kube-bench-footloose-ignite/master/prepare.sh
chmod +x prepare.sh
./prepare.sh

# Build kluster Docker image
# This image is a workaround to provide the ability to inject custom scripts into the VMs
mkdir kluster
cd kluster
wget https://raw.githubusercontent.com/robertojrojas/kube-bench-footloose-ignite/master/kluster/Dockerfile
wget https://raw.githubusercontent.com/robertojrojas/kube-bench-footloose-ignite/master/kluster/build-docker.sh
wget https://raw.githubusercontent.com/robertojrojas/kube-bench-footloose-ignite/master/kluster/kluster.service
wget https://raw.githubusercontent.com/robertojrojas/kube-bench-footloose-ignite/master/kluster/kluster.sh
chmod +x kluster.sh
chmod +x build-docker.sh
./build-docker.sh
cd ..

## View the footloose config
#vi footloose.yaml.k8s

wget https://raw.githubusercontent.com/robertojrojas/kube-bench-footloose-ignite/master/haproxy.cfg

wget https://raw.githubusercontent.com/robertojrojas/kube-bench-footloose-ignite/master/k8s-master.sh

wget https://raw.githubusercontent.com/robertojrojas/kube-bench-footloose-ignite/master/k8s-worker.sh

chmod +x k8s-master.sh
chmod +x k8s-worker.sh


# make sure DNS is setup correctly.
# You might need to add the following to /etc/hosts
# 172.17.0.2 firekube.luxas.dev
#ping firekube.luxas.dev
wget https://raw.githubusercontent.com/robertojrojas/kube-bench-footloose-ignite/master/footloose.yaml.k8s

sed "s,<ABSOLUTE_PATH>,$(pwd),g" footloose.yaml.k8s > footloose.yaml.k8s.mod

## create cluster vms
footloose --config footloose.yaml.k8s.mod create


# This is needed to route requests to k8s
docker run -d -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg -p 6443:443 haproxy:alpine


# 3-5 mins
export KUBECONFIG=$(pwd)/run/admin.conf
#kubectl get nodes

kubectl get nodes | grep ' Ready    <none>' > /dev/null
until [ $? -eq 0 ]; do
   echo 'waiting for worker to be ready...'
   sleep 5s
   kubectl get nodes | grep ' Ready    <none>' > /dev/null
done

# Execute the kube-bench on a worker node.
wget https://raw.githubusercontent.com/robertojrojas/kube-bench-footloose-ignite/master/job-worker.yaml
kubectl apply -f job-worker.yaml

echo "wait for the kube-bench to execute..."
sleep 10s

kubectl logs $(kubectl get pod --no-headers | grep kube | awk '{print $1}')
