FROM weaveworks/ignite-kubeadm:latest

# Setup Kluster Script
COPY kluster.sh /usr/bin
COPY kluster.service /etc/systemd/system/kluster.service
RUN systemctl enable kluster
