# Pods Disaster Recovery with Volume Snapshots 

## Prerequisites

1. Kubernetes 1.19+ 
2. The [aws-ebs-csi-driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) installed.
3. The [external snapshotter](https://github.com/kubernetes-csi/external-snapshotter) installed.

## Usage

This sample involve how to create a snapshot, restore and resize an EBS `PersistentVolume` of Pods.

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

    Example output: 

    Disaster Recovery in EKS with EBS at Thu Sep 28 09:48:55 UTC 2023
    Disaster Recovery in EKS with EBS at Thu Sep 28 09:49:05 UTC 2023
    Disaster Recovery in EKS with EBS at Thu Sep 28 09:49:15 UTC 2023

    ```

1. Create a `VolumeSnapshot` referencing the `PersistentVolumeClaim` name:
    ```sh
    $ kubectl apply -f ebs-kc-snapshot.yaml

    volumesnapshot.snapshot.storage.k8s.io/ebs-volume-snapshot created
    ```

2. Describe the snapshot and wait for the `Ready To Use:  true` attribute of the `VolumeSnapshot`: 
    ```sh

    kubectl describe volumesnapshot.snapshot.storage.k8s.io/ebs-volume-snapshot | grep -i Status -A6

    ...
    Status:
    Bound Volume Snapshot Content Name:  snapcontent-333215f5-ab85-42b8-b4fc-27a6cba0cc19
    Creation Time:                       2022-09-26T04:09:51Z
    Ready To Use:                        true
    Restore Size:                        2Gi
    ```

3. Delete the existing app and its PVC and Pod:
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

    kubectl exec "appserver-recovery" -- sh -c 'cat /data/out.txt'

    Example output: 

    Disaster Recovery in EKS with EBS at Thu Sep 28 09:48:55 UTC 2023
    Disaster Recovery in EKS with EBS at Thu Sep 28 09:49:05 UTC 2023
    Disaster Recovery in EKS with EBS at Thu Sep 28 09:49:15 UTC 2023
    Disaster Recovery in EKS with EBS at Thu Sep 28 09:49:25 UTC 2023
    ```

10. Let's modify PVCs dynamically to reflect size in the PodulSet:
    ```sh

    kubectl patch pvc appserver-recovery-claim -p '{ "spec": { "resources": { "requests": { "storage": "4Gi" }}}}'

    ```

11. Validate that the new size is 4Gi
    ```sh
    aws ec2 describe-volumes --filters "Name=tag:Name,Values=*pvc*" --query 'Volumes[*].{VOL_ID:VolumeId,Size:Size}' --output 
table
    ```

    Example output:

    ```
    -----------------------------------
    |         DescribeVolumes         |
    +------+--------------------------+
    | Size |         VOL_ID           |
    +------+--------------------------+
    |  4   |  vol-0abcde12345         |
    +------+--------------------------+
  
    ```


1.  Cleanup resources:
    ```sh
    kubectl delete -f ebs-kc-restore.yaml

    kubectl delete -f ebs-kc-snapshot.yaml

    kubectl delete -f ebs-kc-classes.yaml
    ```
