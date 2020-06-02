# MySQL Deployment using persistent volumes

In this demo we are setting up one MySQL Server using k8s, we will use a deployment and NFS as storage.

## Persistent volumes
Setup a NFS Server for your persistent volumes, howto [here](https://github.com/wwwted/Oracle-Cloud/blob/master/nfs.md)
If you are using a public cloud provider you can most likely use dynamic storage options for handling of PV.

In bellow examples I have a NFS Server on IP: 10.0.0.50
The NFS exposes folder:
- /var/nfs/pv099

## Kubernetes configuration
You can look at configuration for kubernetes in [yamls](https://github.com/wwwted/Oracle-Cloud/tree/master/kubernetes-mysql/yamls) folder.

First we are creating a persistent volume and a persistant volume clame.
We are specifying that this volume can only be accessed by one node (ReadWriteOnce)
We are also specifying that we will use our NFS server for storage.
More information on PV [here](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

After we have created the persistent volume we will create the MySQL [deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).
First we create a [service](https://kubernetes.io/docs/concepts/services-networking/service/) to expose our application on the network.
Next we create the MySQL deployment using the resourses created earlier.

1) Create a persisten volume (PV):
```
kubectl create -f yamls/01-mysql-pv.yaml
```

2) Start MySQL using a deplyments (one MySQL Server using NFS PV)
```
kubectl create -f yamls/01-mysql-deployment.yaml
```

Done!

## If you want to remove everything:
```
kubectl delete -f yamls/01-mysql-deployment.yaml 
kubectl delete -f yamls/01-mysql-pv.yaml
Make sure everything is deleted:
kubectl get pv,pv
kubectl get all -o wide
```

Remember to also empty out the datadir on NFS between tests:
```
sudo rm -fr /var/nfs/pv099/*
ls /var/nfs/pv099/
```
