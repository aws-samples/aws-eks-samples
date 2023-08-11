# How to Configure Logging AWS EKS on Fargate to AWS OpenSearch version 1.3 or 2.3

*In this tutorial, we covered 2 scenarios*

- Scenario 1: Logging EKS cluster with Fargate to OpenSearch domain in VPC
- Scenario 2: Logging EKS cluster with Fargate to OpenSearch domain in Public


The Architecture:
```
EKS Fargate Cluster ----> AWS Opensearch 
```

## Pre-requisite
* Install latest [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
* Install latest [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
* An existing AWS EKS Cluster with Fargate Profile or execute the command below to create one.
* For OpenSearch in VPC, you need a form of VPN or Proxy. You can use an EC2 instance in the same VPC and subnet to execute the steps in this tutorial

```
git clone git@github.com:aws-samples/aws-eks-se-samples.git

cd aws-eks-se-samples

eksctl create cluster -f examples/eksctl/how-toeks-fargate/fargate-cluster.yaml 
```

The command above will create an EKS Cluster in a VPC. The VPC details is also used to provision the AWS OpenSearch with VPC Access.

1. Define all my variables as shown below:

```
# name of our Amazon OpenSearch cluster
export ES_DOMAIN_NAME="eksworkshop"

# Elasticsearch version 1.3 or 2.3
export ES_VERSION="OpenSearch_1.3"

# OpenSearch Dashboards admin user
export ES_DOMAIN_USER="eksworkshop"

export AWS_REGION="eu-west-1"
export ACCOUNT_ID=111111222222
export ES_DOMAIN_PASSWORD="XXXXXXXXX"

# these 2 variables are not needed if you are creating AWS OpenSearch with Public Access
export SUBNET_ID="subnet-XXXXXXXXXXX"
export SECURITY_GROUP_ID="sg-XXXXXXXXXX"
```

2. Confirm all the variable above
```
echo ES_DOMAIN_USER: $ES_DOMAIN_USER
echo ES_DOMAIN_PASSWORD: $ES_DOMAIN_PASSWORD
echo ES_VERSION: $ES_VERSION
echo ES_DOMAIN_NAME: $ES_DOMAIN_NAME
echo AWS_REGION: $AWS_REGION
echo ACCOUNT_ID: $ACCOUNT_ID
```

3. Clone the repo

```
git clone https://github.com/aws-samples/aws-eks-se-samples.git
cd aws-eks-se-samples/examples/kubernetes/how-to-logging-eks-fargate-opensearch
```


4. Update the template using the variables created previously depending on your choice of OpenSearch. VPC or Public Access

*For OpenSearch with VPC*
```
cat ./es_domain_vpc.json | envsubst > ./es_domain_vpc_edited.json 
```

*For OpenSearch with Public*
```
cat ./es_domain.json | envsubst > ./es_domain_edited.json 
```

5. Create the AWS OpenSearch cluster if public access
```
aws opensearch create-domain \
  --cli-input-json  file://es_domain_edited.json

# or Create the AWS OpenSearch cluster if vpc access

aws opensearch create-domain \
  --cli-input-json  file://es_domain_vpc_edited.json
```

6. Confirm the opensearch status. It takes a few minute for the cluster to be ready
```   
if [ $(aws opensearch describe-domain --domain-name ${ES_DOMAIN_NAME} --query 'DomainStatus.Processing') == "false" ]
  then
    tput setaf 2; echo "The Amazon OpenSearch cluster is ready"
  else
    tput setaf 1;echo "The Amazon OpenSearch cluster is NOT ready"
fi
```

7. Download the OpenSearch IAM policy to your computer and Create IAM policy
```
curl -O https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/amazon-elasticsearch/permissions.json

aws iam create-policy --policy-name eks-fargate-logging-policy --policy-document file://permissions.json
```

8. From AWS EKS console, get the ARN of the Fargate profile and create additional environment variable
```
export FLUENTBIT_ROLE="arn:aws:iam::XXXXXXXXXX:role/eksctl-fg-cluster-FargatePodExecutionRole-1NJ56STKCDSTS"
export FP_PROFILE="eksctl-fg-cluster-FargatePodExecutionRole-1NJ56STKCDSTS"
```

9. After the AWS OpenSearch domain is created successfully, get the endpoint created for the VPC domain
For AWS OpenSearch with VPC Access
```
export ES_ENDPOINT=$(aws opensearch describe-domain --domain-name ${ES_DOMAIN_NAME} --output text --query "DomainStatus.Endpoints") 
```
or execute command below for AWS OpenSearch with Public Access
```
export ES_ENDPOINT=$(aws opensearch describe-domain --domain-name ${ES_DOMAIN_NAME} --output text --query "DomainStatus.Endpoint") 
```

10.  Attach policy to pod execution role 
```
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::520817024429:policy/eks-fargate-logging-policy \
  --role-name ${FP_PROFILE}
```

11.  Test connectivity to the AWS OpenSearch. If OpenSearch is VPC Access, test from an EC2 instance in the same VPC and subnets as the Fargate Pods or EKS Subnets.
```  
curl https://{ES_ENDPOINT} -k

```

Expected output: Unauthorized


12.   Update the Elasticsearch internal database with the commands below:
- Part 1
```
curl -sS -u "${ES_DOMAIN_USER}:${ES_DOMAIN_PASSWORD}" \
    -X PATCH \
    "https://${ES_ENDPOINT}/_opendistro/_security/api/rolesmapping/all_access?pretty" \
    -H 'Content-Type: application/json' \
    -d'
[
  {
    "op": "add", "path": "/backend_roles", "value": ["'${FLUENTBIT_ROLE}'"]
  }
]
'
```

Expected output:
```
{
  "status" : "OK",
  "message" : "'all_access' updated."
}
```

- Part 2
```
curl -sS -u "${ES_DOMAIN_USER}:${ES_DOMAIN_PASSWORD}" \
    -X PATCH \
    "https://${ES_ENDPOINT}/_opendistro/_security/api/rolesmapping/security_manager?pretty" \
    -H 'Content-Type: application/json' \
    -d'
[
  {
    "op": "add", "path": "/backend_roles", "value": ["'${FLUENTBIT_ROLE}'"]
  }
]
'
```
Expected output:
```
{
  "status" : "OK",
  "message" : "'security_manager' updated."
}
```

13.  To configure the EKS cluster for Fargate logging, Create the 2 files needed for the dedicated namespace and ConfigMap as required:14.  

- Part 1: For OpenSearch version 1.3 - copy and paste command below:
```
cat << EOF > aws-logging-opensearch-configmap.yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: aws-logging
  namespace: aws-observability
data:
  output.conf: |
    [OUTPUT]
      Name  es
      Match *
      Host  vpc-eksworkshop-abcdefg123456yvzop7h6awv2et6ro2i.eu-west-1.es.amazonaws.com 
      Port  443
      Index my_index
      Type  doc
      AWS_Auth On
      AWS_Region eu-west-1
      tls   On
EOF
```

or for OpenSearch version 2.3 - copy and paste command below:

```
cat << EOF > aws-logging-opensearch-configmap2.3.yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: aws-logging
  namespace: aws-observability
data:
  output.conf: |
    [OUTPUT]
      Name  es
      Match *
      Host  vpc-eksworkshop-abcdefg123456yvzop7h6awv2et6ro2i.eu-west-1.es.amazonaws.com 
      Port  443
      Index my_index
      Type  _doc
      AWS_Auth On
      AWS_Region eu-west-1
      tls   On
      Suppress_Type_Name On
EOF
```


Note: Remember to change `vpc-eksworkshop-abcdefg123456yvzop7h6awv2et6ro2i.eu-west-1.es.amazonaws.com`, `my_index` and `eu-west-1` with your own values
For example change `vpc-eksworkshop-abcdefg123456yvzop7h6awv2et6ro2i.eu-west-1.es.amazonaws.com` with the output of the command below:
```
echo ${ES_ENDPOINT}
```

- Part 2: Create the manifests.
```
kubectl apply -f aws-observability-namespace.yaml
kubectl apply -f aws-logging-opensearch-configmap.yaml
```

14.  Before we start seeing logs in AWS OpenSearch, we need to create some example pods that can generate container logs
```
kubectl run test1 --image=nginx 
kubectl run test2 --image=nginx 
```

15. Confirm that the Pod is created with logging enabled: 
```
kubectl describe po test2 | grep log 
  Normal  LoggingEnabled  107s  fargate-scheduler  Successfully enabled logging for pod

kubectl describe po test1 | grep log
  Normal  LoggingEnabled  2m37s  fargate-scheduler  Successfully enabled logging for pod 
```


16. Check AWS OpenSearch to confirm it detects the new Index entered in the configmap
```
curl -sS -u "${ES_DOMAIN_USER}:${ES_DOMAIN_PASSWORD}" \
    -XGET "https://${ES_ENDPOINT}/my_index_vpc?pretty" \
    -H 'Content-Type: application/json'  
```
output:
```
{
  "my_index_vpc" : {
    "aliases" : { },
    "mappings" : {
      "properties" : {
        "@timestamp" : {
          "type" : "date"
        },
        "log" : {
          "type" : "text",
          "fields" : {
            "keyword" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        }
      }
    },
    "settings" : {
      "index" : {
        "creation_date" : "1672942199304",
        "number_of_shards" : "5",
        "number_of_replicas" : "1",
        "uuid" : "nqRr4oMZTp6qODFA7POxpg",
        "version" : {
          "created" : "135248027"
        },
        "provided_name" : "my_index_vpc"
      }
    }
  }
}
```
  
17. To search the index and view data in AWS OpenSearch
    
- Navigate to `OpenSearch Dashboard >> Stack Management >> Index patterns >> Create index pattern`
- Click `Define an index pattern >> Index pattern name >> [the new index name will appear] >> Next >> Configure settings >> from dropdown select "@timestamp" >> click "Create index pattern"` button


# Clean up

## Delete the AWS OpenSearch
```
aws opensearch delete-domain \
    --domain-name ${ES_DOMAIN_NAME}
```

## Clear the environment variables
```
unset ES_DOMAIN_NAME
unset ES_VERSION
unset ES_DOMAIN_USER
unset ES_DOMAIN_PASSWORD
unset FLUENTBIT_ROLE
unset ES_ENDPOINT
```

## Delete the Pods
```
kubectl delete pod test1 
kubectl delete pod test2 
```

## Delete the EKS CLuster
```
eksctl delete cluster -f ./fargate-cluster.yaml 
```