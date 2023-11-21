# EKS Intermittent Connectivity Issues

---

## Prerequisites

- EKS cluster
- kubectl 
- IMDS access
- S3 bucket
- IAM Policy on worker node to allow push to S3

---
## Warning : 

The pods deployed in this sample will have hostNetwork set to true.
A pod can access the network namespace and network resources of the node if it is running in the host network of the node where it is deployed.
In this case, the pod can listen for requests directed to particular addresses which allows users to collect packet captures on a node level from the pod.
Please remove these pods from the cluster as soon as desired data collection completes. 

---

## Usage

When troubleshooting issues related to intermittent connectivity in a cluster that are difficult to reproduce, you can setup a pod that runs tcpdump and streams the packet captures to an S3 bucket for storage and retrieval. This allows users to look into packet captures around the time frame of an issue and analyze the flow of communication to investigate the cause of connectivity drops. 

1. Edit the manifest YAMLs to reflect the S3 bucket name in your account. 
2. You can make changes to the tcpdump command as well to make it more inline with the communication that you're trying to retrieve a packet capture for. Refer : https://linux.die.net/man/8/tcpdump

You would be required to add permissions shared in the manifests section to use the IAM policy required for node to push captures to the S3 bucket. 

--- 

## Getting Started

To keep analysis targetted, first try to figure out if the connectivity issue happens for a particular worker node, set of worker nodes or randomly anywhere across the cluster. Follow the sections below to work with either of the mentineod scenarios. 


#### Particular Worker Node

If you've identified that the issue appears often on a particular worker node, then use nodeSelector in deplyment manifest to ensure that you capture packets from that particular node.  
To setup captures, the deployment manifest would need to be edited to add the value for kubernetes.io/hostname to reflect the node name that you want the pod to be scheduled on. 

#### Set of Worker Nodes

If you've identified the issue to be apperaing for a partciluar set of worker nodes, then use affinity along with labelSelector in deplyment manifest for the set of nodes to schedule pods on those particular nodes. 
Reference : https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#types-of-inter-pod-affinity-and-anti-affinity

#### Randomly any Worker Node

In cases where a particular node or set of nodes can not be identified that lead to connectivity issues, the pod could be run as a daemonset to ensure that pcaps are captured from all the nodes and sent to an existing S3 bucket. 

---

#### Daemonset : 

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app: aws-tcpdump
  name: aws-tcpdump
spec:
  selector:
    matchLabels:
      app: aws-tcpdump
  template:
    metadata:
      labels:
        app: aws-tcpdump
    spec:
      hostNetwork: true
      containers:
      - image: amazon/aws-cli
        name: aws-tcpdump-aws-cli
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        command:
          - sh
          - -c
          - |
            #!/bin/bash
            yum install ethtool bind-utils tcpdump wget -y 
            INSTANCE=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
            while true; 
            do 
            YEAR=$(date +%Y); 
            MONTH=$(date +%m); 
            DAY=$(date +%d); 
            HOUR=$(date +%H); 
            MINUTE=$(date +%M); 
            tcpdump -i any -W1 -G60 -w - | aws s3 cp - s3://<test-dump-eks>/tcp-dumps/${INSTANCE}/${YEAR}-${MONTH}-${DAY}-${HOUR}:${MINUTE}-dump.pcap;
            for i in $(ls /sys/class/net); do ethtool -S $i; done | aws s3 cp - s3://<test-dump-eks>/tcp-dumps/${INSTANCE}/ethtool-${YEAR}-${MONTH}-${DAY}-${HOUR}:${MINUTE}.txt
            done
```

#### Deployment :

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aws-tcpdump
  labels:
    app: aws-tcpdump
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aws-tcpdump
  template:
    metadata:
      labels:
        app: aws-tcpdump
    spec:
      hostNetwork: true
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - aws-tcpdump
              topologyKey: kubernetes.io/hostname
            weight: 100
      containers:
      - command:
          - sh
          - -c
          - |
            #!/bin/bash
            yum install ethtool bind-utils tcpdump wget -y 
            INSTANCE=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
            while true; 
            do 
            YEAR=$(date +%Y); 
            MONTH=$(date +%m); 
            DAY=$(date +%d); 
            HOUR=$(date +%H); 
            MINUTE=$(date +%M); 
            tcpdump -i any -W1 -G60 -w - | aws s3 cp - s3://<test-dump-eks>/tcp-dumps/${INSTANCE}/${YEAR}-${MONTH}-${DAY}-${HOUR}:${MINUTE}-dump.pcap;
            for i in $(ls /sys/class/net); do ethtool -S $i; done | aws s3 cp - s3://<test-dump-eks>/tcp-dumps/${INSTANCE}/ethtool-${YEAR}-${MONTH}-${DAY}-${HOUR}:${MINUTE}.txt
            done
        image: amazon/aws-cli
        imagePullPolicy: Always
        name: aws-tcpdump-aws-cli
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      restartPolicy: Always

```
