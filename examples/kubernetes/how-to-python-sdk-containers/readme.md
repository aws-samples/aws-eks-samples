# Sample pod running AWS Python SDK with web federated identity provider as credential provider

*When building containers in pods that uses AWS SDK, it is recommended to use IAM roles for service accounts to provide authentication for the pods.*

*When using [IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html), the containers in your pods must use an AWS SDK version that supports assuming an IAM role through an OpenID Connect web identity token file.*

## Pre-requisite
* An existing AWS EKS Cluster.
* Install latest [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
* Install latest [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
* The following versions, or later, for your [AWS SDK](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-minimum-sdk.html):


## Steps Summary:
- Configure IRSA - refer to steps in [here](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) 
- Create Service Account in the Cluster e.g `aws-sdk`
- Annotate the Kubernetes `serviceAccountName: aws-sdk` with the IAM role
- Deploy pods to use a Kubernetes service account 


## Getting Started
1. Create Namespace 
```
kubectl create namespace my-namespace
e.g.
kubectl create namespace serverless
```


2. Create a file that includes the permissions for the AWS services that you want your pods to access. 

```
cat >my-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:*",
            "Resource": "*"
        }
    ]
}
EOF
```

3. Create the IAM policy.
```
aws iam create-policy --policy-name my-policy --policy-document file://my-policy.json
```
Note the policy arn in the output generate by the command.

4. Create an IAM role and associate it with a Kubernetes service account. You can use `eksctl` or `aws cli`
   
*4a. Using `eksctl`.*

```
eksctl create iamserviceaccount --name my-service-account \
    --namespace my-namespace \
    --cluster my-cluster \
    --role-name "my-role" \
    --attach-policy-arn arn:aws:iam::ACCOUNT_ID:policy/my-policy --approve
```
Replace `my-cluster` with your EKS cluster name. Replace `my-service-account`, `my-namespace`, and `ACCOUNT_ID` with your values. Replace `my-role` with the name of the role that you want to associate the service account to. If it doesn't already exist, eksctl creates it for you.


*4b. Using `Kubectl` and `AWS CLI`*

- Create Service Account
```
kubectl create -f service-account.yaml
```

- Execute the commands below to create the IAM role with trust policy attached to it.
```
account_id=$(aws sts get-caller-identity --query "Account" --output text)

oidc_provider=$(aws eks describe-cluster --name my-cluster --region $AWS_REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")

export namespace=serverless
export service_account=aws-sdk

cat >trust-relationship.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$account_id:oidc-provider/$oidc_provider"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "$oidc_provider:aud": "sts.amazonaws.com",
          "$oidc_provider:sub": "system:serviceaccount:$namespace:$service_account"
        }
      }
    }
  ]
}
EOF

aws iam create-role --role-name my-role --assume-role-policy-document file://trust-relationship.json --description "my-role-description"

aws iam attach-role-policy --role-name my-role --policy-arn=arn:aws:iam::$account_id:policy/my-policy

```

Replace service account `aws-sdk` with the Kubernetes service account that you want to assume the role. Replace `serverless` with the namespace of the service account. Replace `my-role` with a name for your IAM role, and `my-role-description` with a description for your role.

- Annotate the service account
```
kubectl annotate serviceaccount -n $namespace $service_account eks.amazonaws.com/role-arn=arn:aws:iam::$account_id:role/my-role
```

5. Deploy the sample Pod running a container built with Python AWS SDK
   
```
kubectl create -f ec2-lister.yml
```

*The example pod will list the first EC2 instance in your account*

6. Verify the result

```
kubectl logs pod/ec2-lister -n serverless
```

Example Output:
```
['i-0abcded123321de513b']
```

