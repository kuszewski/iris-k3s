#!/bin/bash


# Configuration
frequency=3
superserverPort=52773
mirrorStatusPath="csp/bin/mirror_status.cxw"
mirrorRoleLabel="intersystems.com/mirrorRole"
podSelector="-l intersystems.com/component=data"
quiet=0

usage() { echo "Usage: $0 [-f frequencySeconds] [-s superServerPort] [-p kubectlPodSelectorStatement]" 1>&2; exit 1; }

while getopts f:s:p:q: flag
do
    case "${flag}" in
        f) frequency=${OPTARG};;
        s) superserverPort=${OPTARG};;
        p) podSelector=${OPTARG};;
        q) quiet=1;;
        *) usage;;
    esac
done

# Connects to the mirror_status endpoint of a data pod and sses kubectl to label the data pod with the correct mirror status
#  arg: podName
#  Example:  labelDataPod iris-demo-0-0
labelDataPod(){
    podName=$1
    podIP=$(kubectl get pod $podName -o jsonpath="{.status.podIP}")
    httpResponseCode=`curl -s -o /dev/null -w "%{http_code}"  http://$podIP:$superserverPort/$mirrorStatusPath`

    mirrorStatus="backup"
    if [ $httpResponseCode = 200 ]
    then
        mirrorStatus="primary"
    fi

    (kubectl label pods $podName $mirrorRoleLabel=$mirrorStatus --overwrite > /dev/null)

    if [ $quiet = 0 ]
    then
        echo "  $podName is $mirrorStatus.  (Confirmed with $podIP returning $httpResponseCode)"
    fi

    return $?
}

# Selects the pods (by default all data pods) and label each appropriately
findAndLabelPods(){
    pods=$(kubectl get pod $podSelector -o jsonpath="{.items[*].metadata.name}")

    for i in $pods
    do
        status=`labelDataPod $i`
        echo $status
    done
}

while [ 1 ]; do
    if [ $quiet = 0 ]
    then
        echo "Checking pods"
    fi
    findAndLabelPods
    sleep $frequency
done

