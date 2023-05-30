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

#### Set of Worker Nodes

If you've identified the issue to be apperaing for a partciluar set of worker nodes, then use affinity along with labelSelector for the set of nodes to schedule pods on those particular nodes. 
Reference : https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#types-of-inter-pod-affinity-and-anti-affinity

#### Randomly any Worker Node

In cases where a particular node or set of nodes can not be identified that lead to connectivity issues, the pod could be run as a daemonset to ensure that pcaps are captured from all the nodes and sent to an existing S3 bucket. 


--- 

## Advanced Options

