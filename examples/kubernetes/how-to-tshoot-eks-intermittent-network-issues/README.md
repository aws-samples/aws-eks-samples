# EKS Intermittent Connectivity Issues

---

## Prerequisites

- EKS cluster
- kubectl 
- IMDS access
- S3 bucket

---

## Usage

When troubleshooting issues related to intermittent connectivity in a cluster that are difficult to reproduce, you can setup a pod that runs tcpdump and streams the packet captures to an S3 bucket for storage and retrieval. This allows users to look into packet captures around the time frame of an issue and analyze the flow of communication to investigate the cause of connectivity drops. 

--- 

## Getting Started

To keep analysis targetted, first try to figure out if the connectivity issue happens for a particular worker node, set of worker nodes or randomly anywhere across the cluster. Follow the sections below to work with either of the mentineod scenarios. 


#### Particular Worker Node

If you've identified that the issue appears often on a particular worker node, then use nodeSelector to ensure that you capture packets from that particular node.  
To setup captures, the deployment manifest would need to be edited to add the value for kubernetes.io/hostname to reflect the node name that you want the pod to be scheduled on. 

- Set of Worker Nodes


- Randomly any Worker Node

