# IRIS in Kubernetes for the desktop

If you want to gain experience with IRIS in Kubernetes, this is for you.  This document walks you through:
 
1. Installation of a micro kubernetes server designed for desktop development and edge computing needs.
2. Installation of IKO
3. Prepare to create an IRIS cluster
4. Creation of sample IRIS clusters using IKO


## Part 1. Installation of k3s and k3d

k3s is a lightweight Kubernetes distribution.  It's full-featured and 100% compliant with the Kubernetes standards.  You can read more about it at https://k3s.io/

k3d is a wrapper around k3s to enable running k3s on your desktop in Docker.  https://k3d.io/ for more info.

### Pre-requisites

Before you install k3d, you'll need to install docker and the kubernetes control tool, kubectl.  For MacOS users, installation is easier if you have brew installed (https://brew.sh/).  For Windows users, chocolatey is similarly helpful (https://chocolatey.org/).  So, please make sure you have those tools installed.

Kubernetes, like many systems, is command-line oriented, so you'll want to have your shell handy.

1. Install Docker. If you don't have it already, 
 - MacOS: `brew cask install docker`
 - Windows:  https://hub.docker.com/editions/community/docker-ce-desktop-windows/
 - Ubuntu: https://docs.docker.com/engine/install/ubuntu/  
2. Install kubectl. If you haven't used kubernetes yet, you probably don't have kubectl installed on your machine.
 - MacOS: `brew install kubernetes-cli`  
 - Windows and Linux: Follow the full instructions here:  https://kubernetes.io/docs/tasks/tools/install-kubectl/

### Installing k3d

The full instlation instructions are on https://k3d.io/#installation

* Mac OS: use brew to install via `brew install k3d`
* Windows: download the executable from https://github.com/rancher/k3d/releases and add it to your path
* Ubuntu: `wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash`

### Create a Kubernetes cluster

Now that you have k3d installed, you can create a kubernetes cluster via the following command:

`k3d cluster create --api-port 6550 -p "8081:80@loadbalancer" --agents 2`

This creates a kubernetes cluster and sets up the networking in docker where any ingress you set up on port 80 in the kubernetes cluster will be available in port 8081 on localhost.  This is incredibly convienient when working on your laptop because you can set up ingress in the normal Kubernetes manner and access it locally without hard-coding IP addresses, editing hosts files, or usiug public cloud load balancers.  We'll demonstrate this once we have an IRIS cluster installed.

## Part 2. Install InterSystems Kubernetes Operator

Now that we have a kubernetes cluster, let's install IKO!

### Install Helm

Helm can be thought of as a package manager for Kubernetes.  You can read more about how to install it at https://helm.sh/docs/intro/install/

* MacOs: `brew install helm`
* Windows: `choco install kubernetes-helm`
* Ubuntu: https://helm.sh/docs/intro/install/#from-apt-debianubuntu

### Create kubernetes secret for access to containers.intersystems.com

Kubernetes has a built-in way of storing secret information.  In this step, we'll create a secret that that will allow Kubernetes to use containers on InterSystems's container registry.

Log into https://containers.intersystems.com.  That will show you your access token.  Then go to the shell and run the following:

`kubectl create secret docker-registry intersystems-container-registry-secret --docker-server=https://containers.intersystems.com --docker-username=<YOUR USERNAME> --docker-password='<YOUR TOKEN>'`

### Download IKO

At present we need to download a tarball that has configurations and details for Helm, the Kubernetes package manager that helps us in deploying our Operator.
In the WRC portal, Select
`Actions -> Software Distribution -> Components`
In the Name searchbox type `kubernetes` and select the latest.  

This is a compressed file.  Uncompress it into this directory.

Replace the `values.yaml` file in the `chart/iris-operator` directory with the one in this directory.

### Install IKO using helm

Finally, we can install IKO on our Kubernetes cluster.  From the IKO directory, run:

`helm install intersystems chart/iris-operator`

Once this has completed, you can check on the status of kubernetes operator with the following command:

`kubectl --namespace=default get deployments -l "release=intersystems, app=iris-operator"`

```
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
intersystems-iris-operator   0/1     1            0           13s
```

It'll take a few seconds to start up.  Keep checking on it and it should eventually look like this:

```
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
intersystems-iris-operator   1/1     1            1           42s
```

If you want more detail on it's status, you can use `kubectl describe` like this:

`kubectl describe pod intersystems-iris-operator`

## Part 3. Prepare to Create an IRIS cluster in Kubernetes

We now have a Kubernetes cluster running with IKO installed, let's create an IRIS instance.  We'll need to do some one-time setup first.

### Create a license key secret

IRIS, as you know, requires a license key.  Get an `iris.key` file that is appropriate for containers and run the following command,

`kubectl create secret generic iris-key-secret --from-file=iris.key`

This will add the iris.key file as a secret in Kubernetes.  This will be pulled into the IRIS pods by IKO.

### Create a Configuration Parameter File ConfigMap

When using containers, IRIS is configured via the configuration parameter files.  We've provided two in the IKO Samples directory that are good place to start.  Let's load them into Kubernetes.

`kubectl create cm iris-cpf --from-file data.cpf --from-file compute.cpf`

To learn more about CPF, check out the IRIS documentation at: https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RACS_CPF

### Create storage class

Kubernetes allows for working with many different storage subsystems through the concept of a storageClass.  Let's add a storage class that will just pull files from your local machine.

`kubectl apply -f storageClass-k3s.yaml`

In the IKO samples directory, we have several other example storageClass (sc) files available for public clouds.  You can read more about storage classes here: https://kubernetes.io/docs/concepts/storage/storage-classes/


## Part 4. Create your first IRIS cluster

Let's start with a very simple, one node, IRIS instance.  If you look at `irisCluster-basic.yaml`, it creates an IRIS instance with just one data node and with the default system password.  The full instructions that describe this yaml file and how to change the password are included in https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=AIKO


Create an IRIS cluster named `iris-demo-basic` with the following command:
`kubectl apply -f irisCluster-basic.yaml`

### Ensuring the cluster started properly

It typically takes a couple of minutes to create the database volumes on your machine.  Here are some ways that you can check on the status of your cluster and the pods that go into it.

`kubectl get iriscluster`
```
NAME              DATA   COMPUTE   MIRRORED   STATUS    AGE
iris-demo-basic   1      0                    Running   23m
```

You can check in on the status of each node in your cluster via

`kubectl get pods`
```
NAME                                          READY   STATUS    RESTARTS   AGE
intersystems-iris-operator-7bb6cd4865-7l9cr   1/1     Running   2          20h
iris-demo-basic-data-0                        1/1     Running   0          3m24s
```

Here we see two pods running.  The first is the worker engine for IKO that is responsible for responding to irisCluster create/delete/update events and making the appropriate changes.  The second pod is the one node in the basic iris cluster.  

Kubectl has two commands that are helpful for checking in on your Kubernetes infrastructure - `kubectl describe` and `kubectl logs`

`kubectl describe` can be used to get detailed information about any Kubernetes resource.  Along with basic information like what kind of object it is, at the bottom of the output you'll also see a list of events that have happened.  This is especially useful when you want to see if downloading the container image was successful or you want to check in on the status of creating a disk volume.  You can try this with `kubectl describe irisCluster iris-demo-basic`

`kubectl logs` is used to get the logs for any pod.  For example `kubectl logs iris-demo-basic-data-0` will show you the IRIS logs for our basic demo cluster.

## Connecting to the IRIS instance

You can use `kubectl exec` to run a command on the IRIS pod.  Here's an example of how you'd start a shell on the pod:
```
kubectl exec --stdin --tty iris-demo-basic-data-0 -- /bin/bash
```
This will open a bash shell on the IRIS pod.  Feel free to explore the container.  You'll be logged in as irisuser, so don't explect to have root access (this is a security best practice for containers).

## Accessing the management portal

But what about accessing the management portal?  

We use the concept of a service to organize network traffic within the Kubernetes cluster.  Here's how you can see the services running.

`kubectl get services`
```
NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)              AGE
kubernetes                   ClusterIP   10.43.0.1       <none>        443/TCP              9h
intersystems-iris-operator   ClusterIP   10.43.13.131    <none>        443/TCP              8h
iris-svc                     ClusterIP   None            <none>        <none>               8h
iris-demo-basic              ClusterIP   10.43.163.185   <none>        1972/TCP,52773/TCP   4h7m
```

The iris-demo-basic service provides a VIP within the cluster for the data nodes in our irisCluster.  Now we need to provide a way to route traffic to the service from outside the Kubernetes cluster.  This is done via an ingress.

`kubectl apply -f ingress-basic.yaml`

Now that we have an ingress, we should be able to route traffic from your local browser to IRIS:

http://localhost:8081/csp/sys/UtilHome.csp

## Cleanup

When you're done, here's how to clean up.

### Cleaning up an irisCluster

You can use the command `kubectl delete irisCluster <CLUSTER NAME>` to remove the pods, statefulsets, services, etc associated with the IRIS instance.  This intentionally leaves behind the PersistentVolumes (disks) where your data is stored, in case you need it later.

`kubectl get persistentvolumeclaim` will show you all of the claims to disks configured in your cluster and `kubectl delete persistentvolumeclaim <CLAIM NAME>` can be used to delete the claim.  

Once the claims are deleted you can delete the actual underlying data by removing the persistentVolumes.  `kubectl get persistentVolume` shows the volumes out there and `kubectl delete persistentVolume` can be used to delete them.

### Stopping Kubernetes

We're using `k3d` to manage the Kubernetes cluster(s).

You can get the list of clusters you have on your machine via: `k3d cluster list`
```
NAME          SERVERS   AGENTS   LOADBALANCER
k3s-default   1/1       2/2      true
```

You can *stop* and *delete* a cluster.  Stopping a cluster, as you'd guess from the name, will stop the docker containers that make up the cluster, but leave their configuration and data.  Deleting a cluster will stop the cluster and it will permanently remove its configuration. 

`k3d cluster stop k3s-default` will stop the cluster named k3s-default


## TODO

* Additional content on passwordhash and how/where we recomend setting the system password
* Descriptions of all the resources created by IKO and how they fit together.  
* Images that describe the cluster and ingress configuration.
* Further information on Ingress, IAM, and the web gateway as they overlap quite a bit.
* Private Docker registry