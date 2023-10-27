***Status:** Work-in-progress. Please create issues or pull requests if you have ideas for improvement.*

# **Amazon EKS Samples**
Example manifests for different workloads samples that you can deploy in Amazon EKS cluster.

## Summary
This project demonstrates different examples of Kubernetes manifests, helm charts, `eksctl` config files that you can use in Amazon EKS.

## Disclaimer
This project is an example of different Kubernetes resource samples and are meant to be used for testing and learning purposes only. 

Do not use in a production environment. Always refer to [Amazon EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/security/docs/) when using Amazon EKS.


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

## CI Scan with Checkov

The kubernetes resource are continuously scanned using [Checkov](https://www.checkov.io/5.Policy%20Index/kubernetes.html) with some checks being skipped. See below:

|Checks	|Details	|Reasons	|
|---	|---	|---	|
|CKV2_K8S_6	|Minimize the admission of pods which lack an associated NetworkPolicy	|All Pod to Pod communication is allowed by default for easy experimentation in this project. Amazon VPC CNI now supports [Kubernetes Network Policies](https://aws.amazon.com/blogs/containers/amazon-vpc-cni-now-supports-kubernetes-network-policies/) to secure network traffic in kubernetes clusters	|
|CKV_K8S_8	|Liveness Probe Should be Configured	|For easy experimentation, no health checks is to be performed against the container to determine whether it is alive or not. Consider implementing [health checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) in a production cluster.	|
|CKV_K8S_9	|Readiness Probe Should be Configured	|For easy experimentation, no health checks is to be performed against the container to determine whether it is alive or not. Consider implementing health checks in a production cluster.	|
|CKV_K8S_14	|Image Tag should be fixed - not latest or blank	|We've opted to fetch the latest Images from the Amazon ECR Public Gallery to ensure each sample is deployed with most recent versions. See [recommendations for container images](https://kubernetes.io/docs/concepts/security/security-checklist/#images).	|
|CKV_K8S_21	|The default namespace should not be used	|To help promote flexible experimentation, Short-lived samples use the default namespace and should be deleted upon test completion. We recommend that you do not use the default namespace in large production systems. For prod, [ensure default namespace is not used](https://docs.bridgecrew.io/docs/bc_k8s_20)	|
|CKV_K8S_22	|Use read-only filesystem for containers where possible	|We've made an exception for Cassandra workload that requires are Read/Write file system. [Configure your images with read-only root file system](https://aws.github.io/aws-eks-best-practices/security/docs/pods/#configure-your-images-with-read-only-root-file-system)	|
|CKV_K8S_23	|Minimize the admission of root containers	|We've used publicly available container images in this project for customers' easy access. For test purposes, the container images user id are left intact. See [guidance](https://docs.docker.com/engine/reference/builder/#user) on building images with specified user ID.  	|
|CKV_K8S_25	|Minimize the admission of containers with added capability	|We've made an exception for Cassandra workload that requires added capability. See Container [Capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for more. 	|
|CKV_K8S_28	|Minimize the admission of containers with the NET_RAW capability	|Exception for nginx workload that requires added capability. We [recommend](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) you define at least one PodSecurityPolicy (PSP) to prevent containers with NET_RAW capability from launching in a production environment.	|
|CKV_K8S_35	|Prefer using secrets as files over secrets as environment variables	|While it secret has not been included in this samples, consider using a secret in an environment variable. You can use [secrets from Secrets Manager and parameters from Parameter Store](https://docs.aws.amazon.com/eks/latest/userguide/manage-secrets.html) as files mounted in Amazon EKS Pods. 	|
|CKV_K8S_37	|Minimize the admission of containers with capabilities assigned	|For easy experimentation, we've made exception for nginx workload that requires added capability. For production purposes, we recommend [capabilities field](https://aws.github.io/aws-eks-best-practices/security/docs/pods/#linux-capabilities) that allows granting certain privileges to a process without granting all the privileges of the root user.  	|
|CKV_K8S_40	|Containers should run as a high UID to avoid host conflict	|We've opted to publicly accessible images from the Amazon ECR Public Gallery. For test purposes, the container images user id are left intact. See [how to define UID](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod).	|
|CKV_K8S_43	|Image should use digest	|We've opted to fetch the latest Images from the Amazon ECR Public Gallery to ensure each sample is deployed with most recent versions. In some production cases you may prefer to use a fixed version of an image, rather than update to newer versions and you can [pull an image by its digest](https://docs.bridgecrew.io/docs/bc_k8s_39). 	|




