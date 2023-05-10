# EKS Intermittent Connectivity Issues

---

## Prerequisites

- EKS cluster
- kubectl 
- IMDS access

---

## Usage

When troubleshooting issues related to intermittent connectivity in a cluster that are difficult to reproduce, you can setup a pod that runs tcpdump and streams the packet captures to an S3 bucket for storage and retrieval. This allows users to look into packet captures around the time frame of an issue and analyze the flow of communication to investigate the cause of connectivity drops. 

--- 

## Getting Started

To keep analysis targetted, first try to figure out if the connectivity issue happens for a particular worker node, set of worker nodes or randomly anywhere across the cluster. Follow the sections below to work with either of the mentineod scenarios. 


- Particular Worker Node

- Set of Worker Nodes

- Randomly any Worker Node


```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app: netshoot
  name: netshoot
spec:
  selector:
    matchLabels:
      app: netshoot
  template:
    metadata:
      labels:
        app: netshoot
    spec:
      hostNetwork: true
      containers:
      - image: nicolaka/netshoot
        name: netshoot-aws-cli
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
            python3 -m venv /eksnodetcpdump
            . /eksnodetcpdump/bin/activate
            pip3 install --upgrade pip
            pip3 install awscli
            aws --version
            INSTANCE=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
            echo $INSTANCE
            while true; 
            do 
            YEAR=$(date +%Y); 
            MONTH=$(date +%m); 
            DAY=$(date +%d); 
            HOUR=$(date +%H); 
            MINUTE=$(date +%M); 
            tcpdump -i any -W1 -G60 -w - | aws s3 cp - s3://<S3BucketName>/tcp-dumps/${INSTANCE}/${YEAR}-${MONTH}-${DAY}-${HOUR}:${MINUTE}-dump.pcap;
            for i in $(ls /sys/class/net); do ethtool -S $i; done | aws s3 cp - s3://<S3BucketName>/tcp-dumps/${INSTANCE}/ethtool-${YEAR}-${MONTH}-${DAY}-${HOUR}:${MINUTE}.txt
            done
```
