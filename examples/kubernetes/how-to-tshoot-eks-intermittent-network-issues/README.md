# EKS Intermittent Connectivity Issues

---

## Prerequisites

- EKS cluster 


## Usage

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
