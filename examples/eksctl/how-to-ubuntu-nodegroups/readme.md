# How to Create Ubuntu Manage Node Group

A tutorial on how to create Ubuntu managed and self-managed node group in AWS EKS


## Prerequisite

* Install latest [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
* Install latest [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
* An existing AWS EKS Cluster. Create an [AWS EKS Cluster](https://github.com/aws-samples/aws-eks-se-samples/tree/main/knowledge-center/how-to-get-started)
   

## Prepare your environment

To define the parameters needed to create node groups, run the commands below:

```
CLUSTER_NAME=cluster-name

REGION=region_code

SERVICE_IPV4_CIDR=$(aws eks describe-cluster --region $REGION --name $CLUSTER_NAME --query cluster.kubernetesNetworkConfig.serviceIpv4Cidr --output text)

IP_FAMILY=$(aws eks describe-cluster --region $REGION --name $CLUSTER_NAME --query cluster.kubernetesNetworkConfig.ipFamily --output text)

if [[ "${IP_FAMILY}" == "ipv4" ]]; then
    DNS_CLUSTER_IP=${SERVICE_IPV4_CIDR%.*}.10
elif [[ "${IP_FAMILY}" == "ipv6" ]]; then
  SERVICE_IPV6_CIDR=$(aws eks describe-cluster --name $CLUSTER_NAME --query cluster.kubernetesNetworkConfig.serviceIpv6Cidr --output text)
  DNS_CLUSTER_IP=$(awk -F/ '{print $1}' <<< $SERVICE_IPV6_CIDR)a
fi 

MAX_POD_VALUE="17"  

API_SERVER_URL=$(aws eks describe-cluster --region $REGION --name $CLUSTER_NAME --query cluster.endpoint --output text)

B64_CLUSTER_CA=$(aws eks describe-cluster --region $REGION --name $CLUSTER_NAME --query cluster.certificateAuthority.data --output text)      

```

Note: Replace cluster_name with your cluster's name and region_code with your AWS region. Calculate the MAX_POD_VALUE based on your [instance type](https://docs.aws.amazon.com/eks/latest/userguide/choosing-instance-type.html#determine-max-pods)


## Verify the parameters

```
echo SERVICE_IPV4_CIDR: $SERVICE_IPV4_CIDR
echo IP_FAMILY: $IP_FAMILY
echo API_SERVER_URL: $API_SERVER_URL
echo B64_CLUSTER_CA: $B64_CLUSTER_CA
echo DNS_CLUSTER_IP: $DNS_CLUSTER_IP
```

## Create the config file

```
cat << EOF > ubuntu-nodegroups.yml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: ${CLUSTER_NAME}
  region: ${REGION}

nodeGroups:
  - name: ubuntu-self-ng
    instanceType: t3.medium
    amiFamily: Ubuntu2004
    desiredCapacity: 1
    minSize: 1
    maxSize: 4
    ssh: # enable SSH using SSM. This won't work for custom AMI
      enableSsm: true 
    overrideBootstrapCommand: |
      #!/bin/bash
      MAX_POD_VALUE="17"                     
      NODE_LABELS="type=selfmanaged"         
      CLUSTER_NAME=${CLUSTER_NAME}           
      API_SERVER_URL=${API_SERVER_URL}       
      B64_CLUSTER_CA=${B64_CLUSTER_CA}       
      source /var/lib/cloud/scripts/eksctl/bootstrap.helper.sh
      # Note "--node-labels=${NODE_LABELS}" needs the above helper sourced to work, otherwise will have to be defined manually.
      /etc/eks/bootstrap.sh ${CLUSTER_NAME} \
        --container-runtime containerd \
        --kubelet-extra-args "--node-labels=${NODE_LABELS} --max-pods=${MAX_POD_VALUE}" \
        --apiserver-endpoint ${API_SERVER_URL} --b64-cluster-ca ${B64_CLUSTER_CA} \
        --dns-cluster-ip ${DNS_CLUSTER_IP} \
        --use-max-pods false

managedNodeGroups:
  - name: ubuntu-man-ng
    instanceType: t3.medium
    ami: ami-0feb1a4a4e739ea4e   # from https://cloud-images.ubuntu.com/aws-eks/
    desiredCapacity: 1
    minSize: 1
    maxSize: 2
    # ssh: # enable SSH using SSM. This won't work for custom AMI
    #   enableSsm: true 
    overrideBootstrapCommand: |
      #!/bin/bash
      MAX_POD_VALUE="17"                      
      NODE_LABELS="type=managed"         
      CLUSTER_NAME=${CLUSTER_NAME}           
      API_SERVER_URL=${API_SERVER_URL}       
      B64_CLUSTER_CA=${B64_CLUSTER_CA}       
      source /var/lib/cloud/scripts/eksctl/bootstrap.helper.sh
      # Note "--node-labels=${NODE_LABELS}" needs the above helper sourced to work, otherwise will have to be defined manually.
      /etc/eks/bootstrap.sh ${CLUSTER_NAME} \
        --container-runtime containerd \
        --kubelet-extra-args "--node-labels=${NODE_LABELS} --max-pods=${MAX_POD_VALUE}" \
        --apiserver-endpoint ${API_SERVER_URL} --b64-cluster-ca ${B64_CLUSTER_CA} \
        --dns-cluster-ip ${DNS_CLUSTER_IP} \
        --use-max-pods false
EOF
```

## create the node groups - the config file will create 2 node groups with 1 worker node each

`eksctl create nodegroup -f ubuntu-nodegroups.yml`    


## Verify the result
```
kubectl get nodes -o=custom-columns=NODE:.metadata.name,OS-Image:.status.nodeInfo.osImage,OS:.status.nodeInfo.operatingSystem,Nodegroup:.metadata.labels.type

NODE                                            OS-Image             OS      Nodegroup
ip-192-168-71-38.eu-west-1.compute.internal     Ubuntu 20.04.5 LTS   linux   selfmanaged
ip-192-168-73-234.eu-west-1.compute.internal    Ubuntu 20.04.5 LTS   linux   managed
```

## Clearn up

`eksctl delete nodegroup -f ubuntu-nodegroups.yml --approve`