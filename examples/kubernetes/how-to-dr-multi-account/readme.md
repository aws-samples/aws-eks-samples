
# Multi-Account Disaster recovery of EBS volume mounted as PVC in AWS EKS Cluster

A tutorial on how to Backup and Restore PVC EBS Volume between EKS Clusters in different AWS Accounts.

```
Source Account: EKS Cluster 1.21 (In-tree) ----> Destination Account: EKS Cluster 1.20 (CSI driver)
```

## Prerequisites

1. Create an [AWS EKS Cluster](https://github.com/aws-samples/aws-eks-se-samples/tree/main/knowledge-center/how-to-get-started) in 2 different AWS accounts. For example below:
Account A - 1111111111111
Account B - 2222222222222

2. Install [EBS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) in the EKS Cluster in Account B. 

3. Clone the repo

```
git clone https://github.com/aws-samples/aws-eks-se-samples.git
cd examples/kubernetes/how-to-dr-multi-account
```

# Dealing with Encrypted Volumes 

1. Create CMK 

- You can't share snapshots that are encrypted with the AWS managed key. Instead, snapshots that you want to share must be encrypted with a customer managed key.
- You can't share encrypted snapshots publicly. To share a snapshot publicly, make sure that it's not encrypted.

```
aws kms create-key \
    --tags TagKey=Purpose,TagValue=K8S \
    --description "k8s PVC key" \
    --profile staging \
    --policy file://Keypolicy.json

output
{
    "KeyMetadata": {
        "AWSAccountId": "1111111111111111",
        "KeyId": "f0f9bdf3-de9c-4d84-af76-822bd72b695d",
        "Arn": "arn:aws:kms:eu-west-1:1111111111111111:key/f0f9bdf3-de9c-4d84-af76-822bd72b695d",
        "CreationDate": "2022-11-10T18:51:41.760000+00:00",
        "Enabled": true,
        "Description": "k8s PVC key",
        "KeyUsage": "ENCRYPT_DECRYPT",
        "KeyState": "Enabled",
        "Origin": "AWS_KMS",
        "KeyManager": "CUSTOMER",
        "CustomerMasterKeySpec": "SYMMETRIC_DEFAULT",
        "KeySpec": "SYMMETRIC_DEFAULT",
        "EncryptionAlgorithms": [
            "SYMMETRIC_DEFAULT"
        ],
        "MultiRegion": false
    }
}
```



2. Create Kubernetes Pod with Persistent storage in the EKS cluster of the source account using EBS in-tree driver.

```
kubectl apply -f pod-ebs-vol-encrypted.yml

```

Verify the deployment:

```
% kubectl get pod,pv,pvc
NAME      READY   STATUS    RESTARTS   AGE
pod/app   1/1     Running   0          4m4s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS   REASON   AGE
persistentvolume/pvc-e12a86eb-cd38-4ce8-b1bc-0a3c79819bb3   4Gi        RWO            Delete           Bound    default/ebs-claim   ebs-sc                  36s

NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/ebs-claim   Bound    pvc-e12a86eb-cd38-4ce8-b1bc-0a3c79819bb3   4Gi        RWO            ebs-sc         4m8s

```

Verify the EBS volume created for the PVC.

```
% aws ec2 describe-volumes --filters "Name=tag-key,Values=*pvc*" --query 'Volumes[*].{ID:VolumeId,Size:Size,Name:[Tags[?Key==`Name`].Value] [0][0]}' --output table --profile staging

--------------------------------------------------------------------------------------------------
|                                         DescribeVolumes                                        |
+------------------------+---------------------------------------------------------------+-------+
|           ID           |                             Name                              | Size  |
+------------------------+---------------------------------------------------------------+-------+
|  vol-03044d189eeccb739 |  kubernetes-dynamic-pvc-e12a86eb-cd38-4ce8-b1bc-0a3c79819bb3  |  4    |
+------------------------+---------------------------------------------------------------+-------+
```

3. Create snapshot from the EBS volume created for the persistent deployment

```
aws ec2 create-snapshot --description "Encrypted PV to another EKS cluster in another Account" --volume-id "vol-03044d189eeccb739" --profile staging

output:
{
    "Description": "Encrypted PV to another EKS cluster in another Account",
    "Encrypted": true,
    "OwnerId": "1111111111111111",
    "Progress": "",
    "SnapshotId": "snap-00400983f1403ef25",
    "StartTime": "2022-11-10T19:04:24.789000+00:00",
    "State": "pending",
    "VolumeId": "vol-03044d189eeccb739",
    "VolumeSize": 4,
    "Tags": []
}
```


4. Share snapshot with another account

```
aws ec2 modify-snapshot-attribute \
    --snapshot-id snap-00400983f1403ef25 \
    --attribute createVolumePermission \
    --operation-type add \
    --user-ids 222222222222 \
    --profile staging
```

Note: copy the encrypted snapshot to your account - If the source snapshot is encrypted, or if your account is enabled for encryption by default, then the snapshot copy is automatically encrypted and you can't change its encryption status.


5. Create a copy of the shared snapshot in your account, and encrypt the copy with a KMS key that you own. Below will use the defaul aws/ebs key.
   
```   
aws ec2 copy-snapshot \
    --source-region eu-west-1 \
    --source-snapshot-id snap-00400983f1403ef25 \
    --description "Snapshot from another EKS cluster in another Account" 

output:
{
    "SnapshotId": "snap-0a425f44b7e2f2ef0"
}
```

6. Now we'll create a volume from the snapshot in the availability zone you prefer:

```
aws ec2 create-volume \
    --snapshot-id snap-0a425f44b7e2f2ef0 \
    --availability-zone eu-west-1a \
    --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=k8s-pvc-restored},{Key=purpose,Value=disaster-recovery},{Key=workload,Value=pvc}]'

{
    "AvailabilityZone": "eu-west-1a",
    "CreateTime": "2022-11-10T19:38:58+00:00",
    "Encrypted": true,
    "KmsKeyId": "arn:aws:kms:eu-west-1:222222222222:key/246bc422-02d4-44fd-b27d-fe787e1d6b74",
    "Size": 4,
    "SnapshotId": "snap-0a425f44b7e2f2ef0",
    "State": "creating",
    "VolumeId": "vol-061fdac9f8f1696cb",
    "Iops": 100,
    "Tags": [
        {
            "Key": "Name",
            "Value": "k8s-pvc-restored"
        },
        {
            "Key": "purpose",
            "Value": "disaster-recovery"
        },
        {
            "Key": "workload",
            "Value": "pvc"
        }
    ],
    "VolumeType": "gp2",
    "MultiAttachEnabled": false
}
```

7. Deploy a new persistent deployment in the cluster that has EBS CSI driver for managing EBS volumes

```
kubectl apply -f static-provisioning/manifests-encrypted
```

Verify the result:

```
% kubectl get pod,pv,pvc                          
NAME                              READY   STATUS    RESTARTS   AGE
pod/app                           1/1     Running   0          71s

NAME                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS   REASON   AGE
persistentvolume/test-pv   10Gi       RWO            Retain           Bound    default/ebs-claim                           71s

NAME                              STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/ebs-claim   Bound    test-pv   10Gi       RWO                           74s
```

Describe the pod with the restored volume and confirm it `SuccessfulAttachVolume`.
```
% kubectl describe pod/app                        
Name:         app
...
Events:
  Type     Reason                  Age                From                     Message
  ----     ------                  ----               ----                     -------
  Normal   Scheduled               80s                default-scheduler        Successfully assigned default/app to ip-192-168-18-172.eu-west-1.compute.internal
  Normal   SuccessfulAttachVolume  76s                attachdetach-controller  AttachVolume.Attach succeeded for volume "test-pv"
  Normal   Pulling                 74s                kubelet                  Pulling image "centos"
  Normal   Pulled                  67s                kubelet                  Successfully pulled image "centos" in 7.553997617s
  Normal   Created                 66s                kubelet                  Created container app
  Normal   Started                 66s                kubelet                  Started container app
```


# Clean Up


- In EKS Cluster in Account B, delete the workload

```
kubectl delete -f static-provisioning/manifests-encrypted
```


- In EKS Cluster in Account A, delete the workload

```
kubectl delete -f pod-ebs-vol-encrypted.yml

```