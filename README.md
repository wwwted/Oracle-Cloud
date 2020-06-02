# Oracle-Cloud

### MySQL Demos
MySQL [Demos](https://github.com/wwwted/Oracle-Cloud/tree/master/mysql-demos) contain OCI scripts (in folder [scripts](https://github.com/wwwted/Oracle-Cloud/tree/master/mysql-demos/scripts), see [howto](https://github.com/wwwted/Oracle-Cloud/blob/master/mysql-demos/scripts/howto) for more details) for creating servers on OCI and also scripts (in client [scripts](https://github.com/wwwted/Oracle-Cloud/tree/master/mysql-demos/client-scripts)) for starting the MySQL Server. They easiest way is to create a custom image on OCI and put all client scripts on that image.

There are also some demos on how to setup and run InnoDB Cluster and InnoDB ReplicaSet on OCI in the [demos](https://github.com/wwwted/Oracle-Cloud/tree/master/mysql-demos/demos) folder.

### Manual install of Kubernetes on OCI
In the folder "kubernetes-install" there is a text [file](https://github.com/wwwted/Oracle-Cloud/blob/master/kubernetes-install/K8s-Howto.txt) covering how to install and and setup k8s.

### Running MySQL on Kubernetes
- [MySQL using deployment with persitant volumes](https://github.com/wwwted/Oracle-Cloud/blob/master/kubernetes-mysql/k8s_mysql.md)
- [InnoDB Cluster using StatefulSets](https://github.com/wwwted/Oracle-Cloud/blob/master/kubernetes-mysql/k8s_innodb_cluster.md)
