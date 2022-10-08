# Volume Snapshots for StatefulSet

## Prerequisites

1. Kubernetes 1.19+ 
2. The [aws-ebs-csi-driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) installed.
3. The [external snapshotter](https://github.com/kubernetes-csi/external-snapshotter) installed.

## Usage

This sample involve how to create a snapshot, restore and resize an EBS `PersistentVolume` of StatefulSet.


### Create Snapshot

1. Create the `StorageClass` and `VolumeSnapshotClass`:
    ```sh
    $ kubectl apply -f manifests/classes/

    volumesnapshotclass.snapshot.storage.k8s.io/csi-aws-vsc created
    storageclass.storage.k8s.io/ebs-sc created
    ```

2. Deploy the provided StatefulSet on your cluster along with the `PersistentVolumeClaim`:
    ```sh
    $ kubectl apply -f manifests/app/

    service/cassandra created
    StatefulSet.apps/cassandra created
    ```

3. Validate the `PersistentVolumeClaim` is bound to your `PersistentVolume`.
    ```sh
    % kubectl get pods
    NAME          READY   STATUS    RESTARTS   AGE
    cassandra-0   1/1     Running   0          33m
    cassandra-1   1/1     Running   0          32m
    cassandra-2   1/1     Running   0          30m

    kubectl get pv,pvc
    NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                STORAGECLASS   REASON   AGE
    persistentvolume/pvc-6d68170e-2e51-40f4-be52-430790684e51   2Gi        RWO            Delete           Bound    default/cassandra-data-cassandra-1   ebs-sc                  27m
    persistentvolume/pvc-b3ab4971-37dd-48d8-9f59-8c64bb65b2c8   2Gi        RWO            Delete           Bound    default/cassandra-data-cassandra-0   ebs-sc                  28m
    persistentvolume/pvc-d0403adb-1a6f-44b0-9e7f-a367ad7b7353   2Gi        RWO            Delete           Bound    default/cassandra-data-cassandra-2   ebs-sc                  26m

    NAME                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    persistentvolumeclaim/cassandra-data-cassandra-0   Bound    pvc-b3ab4971-37dd-48d8-9f59-8c64bb65b2c8   2Gi        RWO            ebs-sc         28m
    persistentvolumeclaim/cassandra-data-cassandra-1   Bound    pvc-6d68170e-2e51-40f4-be52-430790684e51   2Gi        RWO            ebs-sc         28m
    persistentvolumeclaim/cassandra-data-cassandra-2   Bound    pvc-d0403adb-1a6f-44b0-9e7f-a367ad7b7353   2Gi        RWO            ebs-sc         26m

    ```

4. Validate the pod successfully wrote data to the volume, taking note of the timestamp of the first entry:
    ```sh
    % for i in {0..2}
    do
    kubectl exec -it cassandra-$i -- lsblk
    done
    NAME          MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
    nvme0n1       259:0    0  80G  0 disk 
    |-nvme0n1p1   259:1    0  80G  0 part /etc/hosts
    `-nvme0n1p128 259:2    0   1M  0 part 
    nvme1n1       259:3    0   2G  0 disk /cassandra_data
    NAME          MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
    nvme0n1       259:0    0  80G  0 disk 
    |-nvme0n1p1   259:1    0  80G  0 part /etc/hosts
    `-nvme0n1p128 259:2    0   1M  0 part 
    nvme1n1       259:3    0   2G  0 disk /cassandra_data
    NAME          MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
    nvme0n1       259:0    0  80G  0 disk 
    |-nvme0n1p1   259:1    0  80G  0 part /etc/hosts
    `-nvme0n1p128 259:2    0   1M  0 part 
    nvme1n1       259:3    0   2G  0 disk /cassandra_data
    `

    # write content to the PVCs. We will use this to test
    for i in {0..2}; do kubectl exec "cassandra-$i" -- sh -c 'echo "$(hostname)" > /cassandra_data/data/file.txt'; done
    for i in {0..2}; do kubectl exec "cassandra-$i" -- sh -c 'echo "$(date)" > /cassandra_data/data/day.txt'; done
    ```

5. Create a `VolumeSnapshot` referencing the `PersistentVolumeClaim` name:
    ```sh
    $ kubectl apply -f manifests/snapshot/

    volumesnapshot.snapshot.storage.k8s.io/ebs-volume-snapshot created
    ```

6. Wait for the `Ready To Use:  true` attribute of the `VolumeSnapshot`: 
    ```sh
    % kubectl apply -f manifests/snapshot/
    volumesnapshot.snapshot.storage.k8s.io/cassandra-data-snapshot-0 created
    volumesnapshot.snapshot.storage.k8s.io/cassandra-data-snapshot-1 created
    volumesnapshot.snapshot.storage.k8s.io/cassandra-data-snapshot-2 created

    ...
    Status:
    Bound Volume Snapshot Content Name:  snapcontent-333215f5-ab85-42b8-b4fc-27a6cba0cc19
    Creation Time:                       2022-09-26T04:09:51Z
    Ready To Use:                        true
    Restore Size:                        2Gi
    ```

7. Delete the existing app:
    ```sh
    kubectl delete -f manifests/app/Cassandra_statefulset.yaml
    statefulset.apps "cassandra" deleted

    # 7a. delete PVCs forcefully. This will delete the PV as well. We don't need the volumes any since we've exhausted the EBS threshold in modifying the volumes.
    for i in {0..2}
    do
    kubectl delete pvc cassandra-data-cassandra-$i --force
    done

    kubectl get pv,pvc 
    No resources found

    ```
### Restore Volume

8. Restore a volume from the snapshot with a `PersistentVolumeClaim` referencing the `VolumeSnapshot` in its `dataSource`:
    ```sh
    kubectl apply -f manifests/snapshot-restore/
    persistentvolumeclaim/cassandra-data-cassandra-0 created
    persistentvolumeclaim/cassandra-data-cassandra-1 created
    persistentvolumeclaim/cassandra-data-cassandra-2 created

    kubectl get pvc
    NAME                         STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    cassandra-data-cassandra-0   Pending                                      ebs-sc         24s
    cassandra-data-cassandra-1   Pending                                      ebs-sc         23s
    cassandra-data-cassandra-2   Pending                                      ebs-sc         22s
    ```

9. Recreate the StatefulSet with the original manifest but with new desired storage size (4Gi). It will use the PVCs restored from the snapshot:
    ```sh
    kubectl apply -f manifests/app-restore/
    StatefulSet.apps/cassandra created
    % kubectl get pvc -w
    NAME                         STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    cassandra-data-cassandra-0   Pending                                      ebs-sc         48s
    cassandra-data-cassandra-1   Pending                                      ebs-sc         47s
    cassandra-data-cassandra-2   Pending                                      ebs-sc         46scassandra-data-cassandra-0   Pending                                      ebs-sc         57s
    cassandra-data-cassandra-0   Pending   pvc-359a87f6-b584-49fa-8dd9-e724596b2b43   0                         ebs-sc         61s
    cassandra-data-cassandra-0   Bound     pvc-359a87f6-b584-49fa-8dd9-e724596b2b43   2Gi        RWO            ebs-sc         61s
    cassandra-data-cassandra-1   Pending                                                                        ebs-sc         112s
    cassandra-data-cassandra-1   Pending                                                                        ebs-sc         112s
    cassandra-data-cassandra-1   Pending   pvc-bcc6f2cd-383d-429d-b75f-846e341d6ab2   0                         ebs-sc         115s
    cassandra-data-cassandra-1   Bound     pvc-bcc6f2cd-383d-429d-b75f-846e341d6ab2   2Gi        RWO            ebs-sc         115s
    cassandra-data-cassandra-2   Pending                                                                        ebs-sc         2m44s
    cassandra-data-cassandra-2   Pending                                                                        ebs-sc         2m44s
    cassandra-data-cassandra-2   Pending   pvc-fa99a595-84b7-49ad-b9c2-1be296e7f1ce   0                         ebs-sc         2m47s
    cassandra-data-cassandra-2   Bound     pvc-fa99a595-84b7-49ad-b9c2-1be296e7f1ce   2Gi        RWO            ebs-sc         2m47s

    ...
    ```

10. verify the content of the EBS storage:
    ```sh
    for i in {0..2}; do kubectl exec "cassandra-$i" -- sh -c 'cat /cassandra_data/data/day.txt'; done
    Sun Sep 25 21:04:33 UTC 2022
    Sun Sep 25 21:04:35 UTC 2022
    Sun Sep 25 21:04:38 UTC 2022
    for i in {0..2}; do kubectl exec "cassandra-$i" -- sh -c 'cat /cassandra_data/data/file.txt'; done
    cassandra-0
    cassandra-1
    cassandra-2
    ```

11. Let's modify PVCs dynamically to reflect size in the StatefulSet:
    ```sh
    for i in {0..2}
    do
    echo "Resizing cassandra-$i"
    kubectl patch pvc cassandra-data-cassandra-$i -p '{ "spec": { "resources": { "requests": { "storage": "4Gi" }}}}'
    done
    Resizing cassandra-0
    persistentvolumeclaim/cassandra-data-cassandra-0 patched
    Resizing cassandra-1
    persistentvolumeclaim/cassandra-data-cassandra-1 patched
    Resizing cassandra-2
    persistentvolumeclaim/cassandra-data-cassandra-2 patched
    ```

12. Validate that the new size is 4Gi
    ```sh
    % for i in {0..2}
    do
    echo "Inspecting cassandra-$i"
    kubectl exec -it cassandra-$i -- lsblk
    kubectl exec -it cassandra-$i -- df -h
    done
    Inspecting cassandra-0
    NAME          MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
    nvme0n1       259:0    0  80G  0 disk 
    |-nvme0n1p1   259:1    0  80G  0 part /etc/hosts
    `-nvme0n1p128 259:2    0   1M  0 part 
    nvme1n1       259:3    0   4G  0 disk /cassandra_data
    Filesystem      Size  Used Avail Use% Mounted on
    overlay          80G  3.0G   78G   4% /
    tmpfs            64M     0   64M   0% /dev
    tmpfs           1.9G     0  1.9G   0% /sys/fs/cgroup
    /dev/nvme1n1    3.9G  1.4M  3.9G   1% /cassandra_data
    /dev/nvme0n1p1   80G  3.0G   78G   4% /etc/hosts
    shm              64M     0   64M   0% /dev/shm
    tmpfs           1.0G   12K  1.0G   1% /run/secrets/kubernetes.io/serviceaccount
    tmpfs           1.9G     0  1.9G   0% /proc/acpi
    tmpfs           1.9G     0  1.9G   0% /sys/firmware
    Inspecting cassandra-1
    NAME          MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
    nvme0n1       259:0    0  80G  0 disk 
    |-nvme0n1p1   259:1    0  80G  0 part /etc/hosts
    `-nvme0n1p128 259:2    0   1M  0 part 
    nvme1n1       259:3    0   4G  0 disk /cassandra_data
    Filesystem      Size  Used Avail Use% Mounted on
    overlay          80G  3.0G   78G   4% /
    tmpfs            64M     0   64M   0% /dev
    tmpfs           1.9G     0  1.9G   0% /sys/fs/cgroup
    /dev/nvme1n1    3.9G  1.4M  3.9G   1% /cassandra_data
    /dev/nvme0n1p1   80G  3.0G   78G   4% /etc/hosts
    shm              64M     0   64M   0% /dev/shm
    tmpfs           1.0G   12K  1.0G   1% /run/secrets/kubernetes.io/serviceaccount
    tmpfs           1.9G     0  1.9G   0% /proc/acpi
    tmpfs           1.9G     0  1.9G   0% /sys/firmware
    Inspecting cassandra-2
    NAME          MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
    nvme0n1       259:0    0  80G  0 disk 
    |-nvme0n1p1   259:1    0  80G  0 part /etc/hosts
    `-nvme0n1p128 259:2    0   1M  0 part 
    nvme1n1       259:3    0   4G  0 disk /cassandra_data
    Filesystem      Size  Used Avail Use% Mounted on
    overlay          80G  3.3G   77G   5% /
    tmpfs            64M     0   64M   0% /dev
    tmpfs           1.9G     0  1.9G   0% /sys/fs/cgroup
    /dev/nvme1n1    3.9G  1.2M  3.9G   1% /cassandra_data
    /dev/nvme0n1p1   80G  3.3G   77G   5% /etc/hosts
    shm              64M     0   64M   0% /dev/shm
    tmpfs           1.0G   12K  1.0G   1% /run/secrets/kubernetes.io/serviceaccount
    tmpfs           1.9G     0  1.9G   0% /proc/acpi
    tmpfs           1.9G     0  1.9G   0% /sys/firmware
    ```


1.  Cleanup resources:
    ```sh
    kubectl delete -f manifests/app-restore
    kubectl delete -f manifests/snapshot-restore
    ```

    ```sh
    $ kubectl delete -f manifests/snapshot
    ```

    ```sh
    $ kubectl delete -f manifests/classes

    volumesnapshotclass.snapshot.storage.k8s.io "csi-aws-vsc" deleted
    storageclass.storage.k8s.io "ebs-sc" deleted

    kubectl delete -f manifests/app/Cassandra_service.yaml
    ```
