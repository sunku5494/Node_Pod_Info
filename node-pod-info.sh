#!/bin/sh

#################
#This script is to troubleshoot https://issues.redhat.com/browse/OCPBUGS-35070 to gather
#the pod count in a worker node from the control plane using oc command, as well as the
#pod count from the SDN CNI directory in a worker node.
#This way we can prove that SDN CNI has some unused IP files and that is causing to not
#finding an IP to allocate from an assigned CIDR to a worker node when a new pod is created in it.

while :; do
	#collect the count of ipv4 files created under CNI_NETWORK_DIR
	CNI_NETWORK_DIR="/var/lib/cni/networks/openshift-sdn"
	ALLOCATED_IPS=$(find $CNI_NETWORK_DIR -type f -regextype posix-extended -regex '.*/([0-9]{1,3}\.){3}[0-9]{1,3}$' | wc -l)

	#collect the count of pods or containers attached to cluster default network created with in a node
	#filter out the pods that dont have Ip address assigned
	POD_COUNT=$(oc --kubeconfig=/var/lib/kubelet/kubeconfig get pods -A \
		--field-selector spec.nodeName="$(hostname)",status.podIP!=null \
		-o json | jq '[.items[] | select(.metadata.annotations["k8s.v1.cni.cncf.io/network-status"] | fromjson? | any(.default))] | length')

	if [ "$POD_COUNT" -ne "$ALLOCATED_IPS" ]; then #validate if count types are string or integer
		echo "ERROR: $(date '+%Y-%m-%d %H:%M:%S') - PODCOUNT from oc: ${POD_COUNT} and PODCOUNT from SDN DIR: ${ALLOCATED_IPS}"
	fi
	echo "Checking!!!!!"
	sleep 10 #set the sleep for one hour
done
