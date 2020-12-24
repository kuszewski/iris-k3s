# Setting up a private container registry in k3s

When you're developing on your machine, having access to your own container registry can speed up development significantly.  This document walks you through the process of setting up a container registry in your kubernetes cluster and configuring k3s to use it.

## Quick install

When you created your kubernetes cluster, the provided command line did two things that we're taking advantage of with this container registry.
1. Exposing NodePorts:  We exposed the standard range of node ports on localhost.  We'll use this fact to expose the container registry to you on localhost port 31113
2. Setting up registry configuration:  We loaded the registry directory onto the kubernetes nodes and configured the node to use that directory.

First, we will create a namespace to place all of our container registry-related items.
```
kubectl create namespace container-registry
```

Now, create the container registry deployment and service.
```
kubectl apply -f container-registry.yaml -n container-registry
```

Finally, we set up a daemonset to add the container registry service to the /etc/hosts files on the kubernetes nodes
```
kubectl apply -f cr-node-setup.yaml -n container-registry
```

That's it!  You've just created a container registry that is running on port 5000 inside the cluster and exposed to your desktop on localhost port 31113.

## Using the container registry

Now that the container registry is running, let's see how to use it.

```
cd example
```

Log into the registry.  This is a one-time setup since docker will cache your credentials.
```
docker login localhost:31113 --username iris --password iris
```

Build the Dockerfile into a container.  The example Dockerfile starts with Ubuntu and just writes "hello world" to the console on startup.
```
docker build -t hello-world-example .
```

Tag the container you just built
```
docker tag hello-world-example:latest localhost:31113/hello-world-example:latest
```

Push the container to your container registry
```
docker push localhost:31113/hello-world-example:latest
```

Your container is now in your private container registry.  You can now use it for any kubernetes load.  Here's an example pod that used the new container:

```
kubectl apply -f pod.yaml
```

If you look at `pod.yaml` you'll see that the image is `container-registry.local:5000` followed by the name and tag of your container.  That's the cluster internal name and port for the container registry.

Let's see if the pod started correctly.

`kubectl get pods`
```
NAME                  READY   STATUS    RESTARTS   AGE
hello-world-example   1/1     Running   0          4s
```

`kubectl logs hello-world-example`
```
hello world
```

You can delete the example pod via `kubectl delete pod hello-world-example`

## Explanation

There are really three areas that need some explanation:
1. Securing up the container registry
2. Configuring the kubernetes backplane and worker nodes (servers and agents in k3s-speak)
3. Ports and hostnames

### Securing the container registry

Container registries should always be using an encrypted connection (https).  For production servers, you'll want to have a real, verifiable, SSL key to secure the container.  But this document covers setting up your own container registry for development purposes on your laptop, so a self-signed certificate is appropriate.  There is a self-signed certificate already included in the `registry/certs` directory.  If you would like to create you own, you can create it with the `openssl` tool as follows:

```
openssl req -x509 -newkey rsa:4096 -days 365 -nodes -sha256 -keyout certs/tls.key -out certs/tls.crt -subj "/CN=docker-registry"
```

While you're at it, you can configure any number of private registries in the `registries.yaml` file.  More on that here: https://rancher.com/docs/k3s/latest/en/installation/private-registry/

Note:  If you change anything in the registry directory, you'll need to restart your kubernetes cluster for k3s to notice the change.  This can be done via:

```
k3s cluster stop
k3s cluster start
```

### Configuring authentication to the container registry

In this example, I've set up the container registry to use basic username/password authentication, as you see with the docker login command.  This information is stored in the `registry/auth/htpasswd` file.  If you want to use a different username/password, you can create the file via

```
docker run --rm --entrypoint htpasswd registry:2.6.2 -Bbn iris iris > auth/htpasswd
```

You'll also need to update the `registry/certs/registries.yaml` file with the new username/password so that kubernetes can authenticate to the container registry and do `docker login` with the new username.  You'll also need to restart your kubernetes cluster as shown above.


### Configuring the kubernetes backplane and worker nodes

The tricky part to running a private container registry is configuring the kubernetes servers to use it.  Each kubernetes distribution handles this differently.  For k3s/k3d, here's what we're doing:

1. When you created the cluster, you told it to mount the `registry` in this repo onto the kubernetes nodes (agents and server).  That was done with the `--volume "$(pwd)/container-registry/registry/":/registry` command line option.
2. Also when you created the cluster, you configured both the agents and servers to use the registries configuration you loaded in the step above this these command line options `--k3s-server-arg "--private-registry=/registry/certs/registries.yaml" --k3s-agent-arg "--private-registry=/registry/certs/registries.yaml"`
3. The last thing we need to do is configure the kubernetes nodes to map the hostname used in the `registries.yaml` file (container-registry.local) to the IP address of the container-registry service we have running in kubernetes.  This can change over time if the registry is started and stopped, so we accomplish this with the `cr-node-setup` daemonset which runs a script on all the nodes to add the correct entry to the `/etc/hosts` file on the kubernetes nodes.

### Ports and Hostnames

There are three parts of the system, each with their own hostname and ports.  This can be a bit confusing, so let me try to explain.

1. When you created the container-registry service, it created an IP address for the service that is accessible within the kubernetes cluster.
2. It _also_ created a nodePort (31113) that is accessible from outside of the kubernetes cluster.  You always use localhost:31113 to access the container registry from your desktop.
3. The `registry` configuration files and `cr-node-setup` configure the kubernetes nodes to use the registry `container-registry.local:5000` for containers that you want to run in your cluster. 

## Further reading

https://medium.com/swlh/deploy-your-private-docker-registry-as-a-pod-in-kubernetes-f6a489bf0180
https://rancher.com/docs/k3s/latest/en/installation/private-registry/
https://github.com/k3s-io/k3s/issues/1713


From your desktop, you can see if the container is running by loading the container registry catalog:
```
curl -sSL -k -u iris:iris -D - https://localhost:31113/v2/_catalog
```