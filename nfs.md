# NFS on OCI

### NFS Server:
Public IP Address:  130.61.145.75
Private IP Address: 10.0.0.50

### Install
sudo yum -y install nfs-utils
sudo systemctl enable nfs-server
sudo systemctl start nfs-server
sudo systemctl status nfs-server

### Exporting paths on the NFS Server
sudo mkdir /var/nfs
sudo mkdir /srv/nfs/kubedata
sudo chown nfsnobody:nfsnobody /var/nfs
sudo chown nfsnobody:nfsnobody /srv/nfs/kubedata
sudo chmod 777 /var/nfs
sudo chmod 777 /srv/nfs/kubedata

Edit /etc/exports, insert line (make /nfs available from all nodes in my NW):
```
/var/nfs           10.0.0.0/24(rw,sync,no_subtree_check,insecure,no_root_squash)
/srv/nfs/kubedata            *(rw,sync,no_subtree_check,insecure,no_root_squash)
```
(no_root_squash - important as MySQL docker image what to run CHOWN)

And run: ```sudo exportfs -a```

Look at: ```showmount -e```

Done!!

### To access NFS mounts from client hosts:
```
sudo mkdir -p /mnt/nfs
mount 10.0.0.50:/var/nfs /mnt/nfs
```
or
```mount -t nfs 10.0.0.50:/var/nfs /mnt/nfs``
To remove mount: ```sudo umount /mnt/nfs```
