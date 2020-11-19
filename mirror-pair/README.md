# IRIS Kubernetes for Desktop - Mirror Pair

If you have alredy run the first iris-basic (sigle instance) on the main landing page of this repository, then you have IKO already running and you should be able to run this mirror-pair example. 

This example leverages the sharding API. 
By default it will create a shard & mirrored database called IRISCLUSTER.
This is a valid use case for customers that know that they will be growing their solution with shard instances.

## Prerequisites
1. Have a k8s cluster running (local k3s assumed)
2. Have container registry secrets defined in k8s
3. Have an IRIS key availabe in the K8s secrets
4. Have IKO running

If any of the above are missing please refer to the previous/root page of this repository.

Please review the *irisCluster-mirror.yaml* irisCluster topology declaration and try to spin it up.

---

# TO DO
- provide a couple of examples of Ingress Controllers picking up the Active Primary
- do we want to provide all the files here again or are we working on the assumption that people will start with the main root page and install K8s and IKO?


