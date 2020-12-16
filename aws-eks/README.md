# Using IKO in AWS EKS

## Creating an EKS cluster for IRIS

The easiest way to create an EKS cluster is with the `eksctl` tool.  With eksctl, you can describe your cluster in a yaml file.  There are many, many options so take your time picking the right configuration for your needs.

### Enabling SSH

If you ever want to be able to SSH into your cluster, you'll need to enable it in your clusterConfig.yaml file and have a keypair to use.  The easiest way to create a keypair is with `ssh-keygen -t rsa`.

### Enabling Hugepages

IRIS performs better when hugepages are used.  In order to make use of them, you need to:

1. Allocate some number of hugepages on the Kubernetes Node when it starts up.  That is done by adding a `preBootstrapCommand` in the `nodeGroup` section of the cluster yaml.  These are shell commands that get run when the VM is started.  In the `clusterConfig.yaml` example included in this directory, I am simply allocating 2048 hugepages.  You'll have to tune this to meet your needs.  Also, you might want multiple nodegroups, some with hugepages and some without to match your workload needs.
2. The pod will need to request some number of hugepages.  This can be done in any Kubernetes pod, but the `irisCluster-hugepages.yaml` file demonstrates how to do it in an irisCluster.

## StorageClass

We have an example StorageClass that works well with AWS EKS.

```
kubectl apply -f iris-ssd-sc-eks.yaml
```

AWS has several storage options, so customers are encouraged to look into what works best for their needs.
