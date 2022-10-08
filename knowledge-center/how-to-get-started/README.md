# **Getting Statrted with AWS EKS CLuster**

## Prerequisites
* Install latest [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
* Install latest [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)

## Create and AWS EKS Cluster
* To create a new AWS EKS Cluster 

```
eksctl create cluster -f create-cluster.yaml
```

## Cleanup

```
eksctl delete cluster -f create-cluster.yaml
```
