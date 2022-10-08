# Getting Started

## Prerequisites
* Install latest [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
* Install latest [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)


# AWS EKS Cluster and existing IAM role

* To create a new AWS EKS Cluster with managed and unmanaged node group using an existing IAM role:

```
eksctl create cluster -f existing-role.yaml
```

or

* To create new managed and unmanaged node groups using an existing IAM role in an existing AWS EKS Cluster with:

```
eksctl create nodegroup -f existing-role.yaml
```

## Cleanup

* To delete a new AWS EKS Cluster with managed and unmanaged node group using an existing IAM role:

```
eksctl delete cluster -f existing-role.yaml
```

or

* To create new managed and unmanaged node groups using an existing IAM role in an existing AWS EKS Cluster with:

```
eksctl delete nodegroup -f existing-role.yaml
```