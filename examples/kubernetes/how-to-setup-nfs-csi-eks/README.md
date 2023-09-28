# How to setup NFS CSI controller on Amazon EKS and deploy a sample app

## Short description

Currently Persistent Volume Dynamic provisioning with Amazon EFS CSI controller has a hard limit of 1000 accesspoints. NFS CSI controller makes use of subdirectories instead of creating access points.

## Pre-requisite

- An existing AWS EKS Cluster.
- Install latest  [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
- Install [kubectl](https://docs.amazonaws.cn/en_us/eks/latest/userguide/install-kubectl.html) 

## Resolution

Deploy the Amazon NFS CSI driver:

1. To deploy the Amazon NFS CSI driver, run the following command:

	```
	curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/v4.1.0/deploy/install-driver.sh  | bash -s v4.1.0 --
	```


2. Create a secret with mountOptions. This is used for DeleteVolumeRequest. (Please note it is namespace specific and created in default namespace)

	```
	kubectl create secret generic mount-options --from-literal mountOptions="nfsvers=4.1,hard"
	```

3. Get the VPC ID for your Amazon EKS cluster:

	```
	aws eks describe-cluster --name your_cluster_name --query "cluster.resourcesVpcConfig.vpcId" --output text
	```

**Note:** In step 3, replace **your_cluster_name** with your cluster name.

4. Get the CIDR range for your VPC cluster:

	```
	aws ec2 describe-vpcs --vpc-ids YOUR_VPC_ID --query "Vpcs[].CidrBlock" --output text
	```

**Note:** In step 4, replace the **YOUR_VPC_ID** with the VPC ID from the preceding step 3.

5. Create a security group that allows inbound network file system (NFS) traffic for your Amazon EFS mount points:

	```
	aws ec2 create-security-group --description efs-test-sg --group-name efs-sg --vpc-id YOUR_VPC_ID
	```

**Note:** Replace **YOUR_VPC_ID** with the output from the preceding step 3. Save the **GroupId** for later.

6. Add an NFS inbound rule so that resources in your VPC can communicate with your Amazon EFS file system:

	```
	aws ec2 authorize-security-group-ingress --group-id sg-xxx --protocol tcp --port 2049 --cidr YOUR_VPC_CIDR
	```

**Note:** Replace **YOUR_VPC_CIDR** with the output from the preceding step 4. Replace **sg-xxx** with the security group ID from the preceding step 5.

7. Create an Amazon EFS file system for your Amazon EKS cluster:

	```
	aws efs create-file-system --creation-token eks-efs
	```

**Note:** Save the **FileSystemId** for later use.

8. To create a mount target for Amazon EFS, run the following command:

	```
	aws efs create-mount-target --file-system-id FileSystemId --subnet-id SubnetID --security-group sg-xxx
	```

**Important:** Be sure to run the command for all the Availability Zones with the **SubnetID** in the Availability Zone where your worker nodes are running. Replace **FileSystemId** with the output of the preceding step 7 (where you created the Amazon EFS file system). Replace **sg-xxx** with the output of the preceding step 5 (where you created the security group). Replace **SubnetID** with the subnet used by your worker nodes. To create mount targets in multiple subnets, you must run the command in step 8 separately for each subnet ID. It's a best practice to create a mount target in each Availability Zone where your worker nodes are running.

**Note:** You can create mount targets for all the Availability Zones where worker nodes are launched. Then, all the Amazon Elastic Compute Cloud (Amazon EC2) instances in the Availability Zone with the mount target can use the file system.

The Amazon EFS file system and its mount targets are now running and ready to be used by pods in the cluster.

Test the Amazon NFS CSI driver:

You can test your Amazon NFS CSI driver with an application that uses dynamic provisioning. The Amazon FileSystem directory is provisioned on demand.

1. Create a Storage Class using storageclass.yaml:

	```
	kubectl apply -f storageclass.yaml
	```

**Note:** Replace FileSystemId with the your actual filesystemID from previous section (step 7). Also replace the region code.

2. Create a pvc and a pod using below yaml:

	```
	kubectl apply -f pod-pvc.yaml
	```

3. Watch the pods in the default namespace and wait for the **app** pod's status to change to **Running**. For example:

	```
	kubectl get pods --watch
	```

4. View the persistent volume created because of the pod that references the PVC:

	```
	kubectl get pv
	```

5. View information about the persistent volume:

	```
	kubectl describe pv your_pv_name
	```

**Note:** Replace **your_pv_name** with the name of the persistent volume returned from the preceding step 4. The value of the **Source.VolumeHandle** property in the output is the ID of the physical Amazon FileSystem created in your account.

6. Verify that the pod is writing data to the volume:

	```
	kubectl exec -it nfs-app -- cat /data/out
	```

**Note:** The command output displays the current date and time stored in the **/data/out** file. The file includes the day, month, date, and time.

