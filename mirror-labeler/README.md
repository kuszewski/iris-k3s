# Mirror Labeler

InterSystems IRIS includes mirroring technology to allow for high availability deployments.  In its most common usage, this is configured as a synchronous mirror pair, where one pod is the primary, or active, node and the other is the backup.

In a mirror pair, you want to send all of your traffic to the primary (active) IRIS server.  Exactly how to do this correctly, depends on your application design.

* IRIS compute nodes are mirror-aware.  If you send your traffic to the compute node, you don't need to worry about which node in the mirror pair is primary.
* The IRIS web gateway is also mirror-aware, so you don't need to worry in that scenario either.

The Mirror labeler can help in deployments without compute or web gateway pods.

## Overview

The Mirror labeler is a Kubernetes deployment that checks the mirror status of every IRIS mirror pair on a periodic basis.  It then sets the `intersystems.com/mirrorRole` label to be `primary` or `backup` on each of their pods.  You can then create a Kubernetes service that points to the primary member of the mirror pair.

## Building the mirror labeler container

You'll find in this directory a Dockerfile that builds a very basic container containing the `monitor.sh` shell script.  Please take some time to review `monitor.sh` to get a better understanding of how it works and to make any modifications to it that are appropriate for your environment.

Build the docker container and push it to your container registry.  The specifics of this command may differ, depending on your container registry, but here is a common example:

```
docker build -t <your_org>/iris-mirror-labeler .
docker push <your_org>/iris-mirror-labeler
```

## Running the mirror labeler in your Kubernetes cluster

Now that the container for the mirror labeler has been created, you can run it in a Kubernetes namespace containing IrisClusters.

1. Create the Role, ServiceAccount, and RoleBinding that allow the mirror labeler to modify labels on pods.  `kubectl apply -f rbac.yaml`
2. Create a deployment that runs the mirror labeler.  You'll need to edit `deployment.yaml` file to insert the docker image reference you created above.
3. Create a service that takes advantage of the `intersystems.com/mirrorRole` label to point to the primary.  A sample of how to do this is provided in `example-service.yaml`.
