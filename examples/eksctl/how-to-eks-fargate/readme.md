# How to create AWS EKS Fargate Cluster

## Pre-requisite
* Install latest [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
* Install latest [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
* An existing AWS EKS Cluster with Fargate Profile or execute the command below to create one.
* For OpenSearch in VPC, you need a form of VPN or Proxy. You can use an EC2 instance in the same VPC and subnet to execute the steps in this tutorial

```
git clone git@github.com:aws-samples/aws-eks-se-samples.git

cd aws-eks-se-samples/examples/eksctl/how-to-eks-fargate

eksctl create cluster -f ./fargate-cluster.yaml 
```

The command above will create an EKS Cluster in a VPC. 

# Clean up

## Delete the EKS CLuster
```
eksctl delete cluster -f ./fargate-cluster.yaml 
```