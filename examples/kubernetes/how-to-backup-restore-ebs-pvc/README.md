# Pods Disaster Recovery with Volume Snapshots 

## Prerequisites

1. Kubernetes 1.19+ 
2. The [aws-ebs-csi-driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) installed.
3. The [external snapshotter](https://github.com/kubernetes-csi/external-snapshotter) installed.

## Usage

This sample involve how to create a snapshot, restore and resize an EBS `PersistentVolume` of Pods.

**Note: The Manifests in this example ensured that each container has a read-only root filesystem. Before applying the manifests, modify the securityContext depending on your use case**

```
    securityContext:
      allowPrivilegeEscalation: true      
      readOnlyRootFilesystem: false 
```


### Create Snapshot

1. Create the `StorageClass` and `VolumeSnapshotClass`:
    ```sh
    $ kubectl apply -f ebs-kc-classes.yaml

    volumesnapshotclass.snapshot.storage.k8s.io/csi-aws-vsc created
    storageclass.storage.k8s.io/disaster-recovery created
    ```

2. Deploy the provided Pod on your cluster along with the `PersistentVolumeClaim`:
    ```sh
    $ kubectl apply -f ebs-kc.yaml

    ```

3. Validate the `PersistentVolumeClaim` is bound to your `PersistentVolume`.
    ```sh
    kubectl get pv,pvc

    ```

4. Validate the pod successfully wrote data to the volume, taking note of the timestamp of the first entry:
    ```sh
    kubectl exec -it appserver -- cat /data/out.txt
    Tue Sep 27 17:06:34 UTC 2022
    Tue Sep 27 17:06:39 UTC 2022

    ```

1. Create a `VolumeSnapshot` referencing the `PersistentVolumeClaim` name:
    ```sh
    $ kubectl apply -f ebs-kc-snapshot.yaml

    volumesnapshot.snapshot.storage.k8s.io/ebs-volume-snapshot created
    ```

2. Wait for the `Ready To Use:  true` attribute of the `VolumeSnapshot`: 
    ```sh
    ...
    Status:
    Bound Volume Snapshot Content Name:  snapcontent-333215f5-ab85-42b8-b4fc-27a6cba0cc19
    Creation Time:                       2022-09-26T04:09:51Z
    Ready To Use:                        true
    Restore Size:                        2Gi
    ```

3. Delete the existing app and its PVC:
    ```sh
    kubectl delete -f ebs-kc.yaml

    ```
### Restore Volume

8. Restore a volume from the snapshot with a `PersistentVolumeClaim` referencing the `VolumeSnapshot` in its `dataSource`:
    ```sh
    kubectl apply -f ebs-kc-restore.yaml
    ```


9.  verify the content of the EBS storage:
    ```sh

    kubectl exec "appserver-recovery" -- sh -c 'cat /data/out.txt'; done
    Tue Sep 27 17:06:34 UTC 2022
    Tue Sep 27 17:06:39 UTC 2022
    Tue Sep 27 17:06:44 UTC 2022
    ```

10. Let's modify PVCs dynamically to reflect size in the PodulSet:
    ```sh

    kubectl patch pvc appserver-recovery-claim -p '{ "spec": { "resources": { "requests": { "storage": "4Gi" }}}}'

    ```

11. Validate that the new size is 4Gi
    ```sh
    aws ec2 describe-snapshots --filters "Name=tag-key,Values=*ebs*" --query 'Snapshots[*].{VOL_ID:VolumeId,SnapshotID:SnapshotId,State:State,Size:VolumeSize,Name:[Tags[?Key==`Name`].Value] [0][0]}' --output table
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    |                                                                  DescribeSnapshots                                                                 |
    +---------------------------------------------------------------------------+-------+-------------------------+------------+-------------------------+
    |                                   Name                                    | Size  |       SnapshotID        |   State    |         VOL_ID          |
    +---------------------------------------------------------------------------+-------+-------------------------+------------+-------------------------+
    |  eksworkshop-eksctl-dynamic-snapshot-d41f920a-0146-4a14-8540-6c961e5809e1 |  4    |  snap-0edcXXXX8XXXXb3 |  completed |  vol-03XXXXXXc1657  |
    +---------------------------------------------------------------------------+-------+-------------------------+------------+-------------------------+
  
    ```


12. Cleanup resources:
    ```sh
    kubectl delete -f ebs-kc-restore.yaml
    persistentvolumeclaim "appserver-recovery-claim" deleted
    pod "appserver-recovery" deleted

    kubectl delete -f ebs-kc-snapshot.yaml
    volumesnapshot.snapshot.storage.k8s.io "ebs-volume-snapshot" deleted

    kubectl delete -f ebs-kc-classes.yaml
    storageclass.storage.k8s.io "disaster-recovery" deleted
    volumesnapshotclass.snapshot.storage.k8s.io "csi-aws-vsc" deleted
    ```
