# InnoDB Cluster on Kubernetes using StatefulSets

In this demo we are setting up InnDB Cluster on Kubernetes, we will use a StatefulSets and NFS as storage.
This demo was created on Oracle Cloud (OCI) but vanilla Kubernetes and NFS was used so should work for any cloud or on-prem.


## Setup NFS Server to act as your persistent volume.
Setup a NFS Server for your persistent volumes, howto [here](https://github.com/wwwted/Oracle-Cloud/blob/master/nfs.md)
If you are using a public cloud provider you can most likely use dynamic storage options for handling of PV.

In bellow example I have a NFS Server on IP: 10.0.0.50
This NFS exposes folders:
- /var/nfs/pv0
- /var/nfs/pv1
- /var/nfs/pv2

## Kubernetes configuration
You can look at configuration for kubernetes in [yamls](https://github.com/wwwted/Oracle-Cloud/tree/master/kubernetes-mysql/yamls) folder.

First we are creating three persistent volumes (pv0-pv2) for our InnoDB Cluster nodes.
We are specifying that this volume can only be accessed by one node (ReadWriteOnce)
We are also specifying that we will use our NFS server for storage.
More information on PV [here](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

After we have created the persistent volumes we will create the [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/). 
StatefulSets is a way in Kubernetes to manage stateful applications
First we create [services](https://kubernetes.io/docs/concepts/services-networking/service/) for our cluster nodes to expose them on the network.
Next we configure our StatefulSet, we want to have three replicas (three InnoDB Cluster nodes) that we are starting in parallel.
We also use the simplified way by defining a volume claim template ([volumeClaimTemplates](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)) that will claim the three previously created volumes.

##### Create PV:
```
kubectl create -f yamls/02-mysql-pv.yaml
kubectl get pv (short for kubectl get persistentvolumes)
               (should be in STATUS Available)
```

##### Create unique namespace for the cluster:
Namespaces in k8s are like comparments in OCI, lets create a unique namespace for our cluster.
```
kubectl create namespace mysql-cluster
kubectl get namespaces
```
Set default namespace for comming commands to mysql-cluster:
```
kubectl config set-context --current --namespace=mysql-cluster
```

##### Start the cluster nodes using StatefulSets
```
kubectl create  -f  yamls/02-mysql-innodb-cluster-manual.yaml
```

##### Look at:
```
kubectl get pv,pvc
watch kubectl get all -o wide
(or kubectl get all -o wide -n mysql-cluster)
(or kubectl get all -o wide --all-namespaces)
```

If there are problems look at logs (mysqld is started direcly + error log is set to stderr in our docker image): 
```
kubectl logs mysql-innodb-cluster-0
```
or prev failed pods by running:
```
kubectl logs -p mysql-innodb-cluster-1
```
Look at configuration for the pod:
```
kubectl describe pod mysql-innodb-cluster-1
```

##### Login to MySQL:
```
kubectl exec -it  mysql-innodb-cluster-0 -- mysql -uroot -p_MySQL2020_
kubectl exec -it  mysql-innodb-cluster-0 -- mysqlsh -uroot -p_MySQL2020_ -S/var/run/mysqld/mysqlx.sock
```

## Create InnoDB Cluster

##### Create admin user for InnoDB Cluster on all nodes:
```
kubectl exec -it  mysql-innodb-cluster-0 -- mysql -uroot -p_MySQL2020_ -e"SET SQL_LOG_BIN=0; CREATE USER 'idcAdmin'@'%' IDENTIFIED BY '
idcAdmin'; GRANT ALL ON *.* TO 'idcAdmin'@'%' WI
TH GRANT OPTION";
kubectl exec -it  mysql-innodb-cluster-1 -- mysql -uroot -p_MySQL2020_ -e"SET SQL_LOG_BIN=0; CREATE USER 'idcAdmin'@'%' IDENTIFIED BY '
idcAdmin'; GRANT ALL ON *.* TO 'idcAdmin'@'%' WI
TH GRANT OPTION";
kubectl exec -it  mysql-innodb-cluster-2 -- mysql -uroot -p_MySQL2020_ -e"SET SQL_LOG_BIN=0; CREATE USER 'idcAdmin'@'%' IDENTIFIED BY '
idcAdmin'; GRANT ALL ON *.* TO 'idcAdmin'@'%' WI
TH GRANT OPTION";
```
##### Create your cluster using shell from one of the pods (mysql-innodb-cluster-0):
Login to shell:
```
kubectl exec -it  mysql-innodb-cluster-0 -- mysqlsh -uidcAdmin -pidcAdmin -S/var/run/mysqld/mysqlx.sock
```
and then configure the instances:
```
dba.configureInstance('idcAdmin@mysql-innodb-cluster-0:3306',{password:'idcAdmin',interactive:false,restart:true});
dba.configureInstance('idcAdmin@mysql-innodb-cluster-1:3306',{password:'idcAdmin',interactive:false,restart:true});
dba.configureInstance('idcAdmin@mysql-innodb-cluster-2:3306',{password:'idcAdmin',interactive:false,restart:true});
```

You see error below when running "dba.configureInstance"
ERROR: Remote restart of MySQL server failed: MySQL Error 3707 (HY000): Restart server failed (mysqld is not managed by supervisor proc
ess).

This is due some limitation running "restart" comand in MySQL for our docker container, we are working on solving this.
Please restart MySQL manually to enable new settings, easiest to scale down + scale up again like:
```
kubectl scale statefulset --replicas=0 mysql-innodb-cluster
```
Look at: ```watch kubectl get all -o wide``` during the scale up/down.
```
kubectl scale statefulset --replicas=3 mysql-innodb-cluster
```

Login to shell again:
```
kubectl exec -it  mysql-innodb-cluster-0 -- mysqlsh -uidcAdmin -pidcAdmin -S/var/run/mysqld/mysqlx.sock
```
and run:
```
cluster=dba.createCluster("mycluster",{exitStateAction:'OFFLINE_MODE',autoRejoinTries:'20',consistency:'BEFORE_ON_PRIMARY_FAILOVER'});
cluster.status()
cluster.addInstance('idcAdmin@mysql-innodb-cluster-1:3306',{password:'idcAdmin',recoveryMethod:'clone'});
cluster.addInstance('idcAdmin@mysql-innodb-cluster-2:3306',{password:'idcAdmin',recoveryMethod:'clone'});
cluster.status()
```
Done, you should now have a running InnoDB Cluster using StatefulSets on Kubernetes.

##### Simulate a failure
Look at cluster status, login to mysql shell:
```
kubectl exec -it  mysql-innodb-cluster-1 -- mysqlsh -uidcAdmin -pidcAdmin -S/var/run/mysqld/mysqlx.sock
```
And look at cluster status:
```
cluster=dba.getCluster()
cluster.status()

``` 
Also look at pods ``` watch kubectl get all -o wide -n mysql-cluster``` 

Kill the pod that is primary (RW) (mysql-innodb-cluster-0 most likely)
```
kubectl delete pod mysql-innodb-cluster-0
```
You should now see that one pod is restarted and that the "old" primary (RW) will join after restart as seconday (RO).


## If you want to remove everything
```
kubectl delete -f yamls/02-mysql-innodb-cluster-manual.yaml
kubectl delete pvc mysql-persistent-storage-mysql-innodb-cluster-0
kubectl delete pvc mysql-persistent-storage-mysql-innodb-cluster-1
kubectl delete pvc mysql-persistent-storage-mysql-innodb-cluster-2
kubectl delete -f yamls/02-mysql-pv.yaml
```
Make sure all is deleted:
```
kubectl get pv,pv
kubectl get all -o wide
```
Remember to also empty out the datadir on NFS between tests:
```
sudo rm -fr /var/nfs/pv[0,1,2]/*
ls /var/nfs/pv[0,1,2]/
```
## Extras
- More information around InnoDB Cluster [here](https://github.com/wwwted/MySQL-InnoDB-Cluster-3VM-Setup)
- Whenever deploying new stuff look at: watch kubectl get all -o wide
- Good training on Kubernetes: https://www.youtube.com/user/wenkatn/playlists
- Good training on Kubernetes: https://github.com/justmeandopensource
