# How to create a simple EKS AutoMode enabled Cluster

## Pre-requisite
* Install latest [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
* Install latest [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)

## Introduction

The eksctl CLI simplifies the process of creating and managing EKS Auto Mode clusters by handling the underlying AWS resource creation and configuration. Before proceeding, ensure you have the necessary AWS credentials and permissions configured on your local machine. This guide assumes you’re familiar with basic Amazon EKS concepts and have already installed the required CLI tools. You can read more about this in the [offical documentation](https://eksctl.io/usage/auto-mode/).

Automode adds a new field to the eksctl CLI that allows users to enable and configure their Automode clusters:
```
autoModeConfig:
    # defaults to false
    enabled: boolean
    # optional, defaults to [general-purpose, system].
    # To disable creation of nodePools, set it to the empty array ([]).
    nodePools: []string
    # optional, eksctl creates a new role if this is not supplied
    # and nodePools are present.
    nodeRoleARN: string
```

With this you can also enable automode for your clusters by updating the `ClusterConfig` file for your existing clusters:
```
# cluster.yaml
...

autoModeConfig:
    enabled: true
```

### Create a simple auto mode enabled cluster
```
eksctl create cluster --enable-auto-mode
```

You can also use the template provided in this repository to enable EKS Auto mode. 

```
eksctl create cluster -f eks-auto.yaml
```



