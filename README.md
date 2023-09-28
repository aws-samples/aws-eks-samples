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
|CKV2_K8S_6	|Minimize the admission of pods which lack an associated NetworkPolicy	|Network Policy is not included in the scope of this project	|
|CKV_K8S_8	|Liveness Probe Should be Configured	|Project is suitable used for testing and learning purposes only	|
|CKV_K8S_9	|Readiness Probe Should be Configured	|Project is suitable used for testing and learning purposes only	|
|CKV_K8S_14	|Image Tag should be fixed - not latest or blank	|We've used latest Images from the Amazon ECR Public Gallery	|
|CKV_K8S_21	|The default namespace should not be used	|Project is suitable used for testing and learning purposes only	|
|CKV_K8S_22	|Use read-only filesystem for containers where possible	|We've made an exception for Cassandra workload that requires are Read/Write file system	|
|CKV_K8S_23	|Minimize the admission of root containers	|We've used publicly available container images  	|
|CKV_K8S_25	|Minimize the admission of containers with added capability	|We've made an exception for Cassandra workload that requires added capability	|
|CKV_K8S_28	|Minimize the admission of containers with the NET_RAW capability	|Exception for nginx workload that requires added capability	|
|CKV_K8S_35	|Prefer using secrets as files over secrets as environment variables	|Not needed in the scope of this project	|
|CKV_K8S_37	|Minimize the admission of containers with capabilities assigned	|Exception for nginx workload that requires added capability	|
|CKV_K8S_40	|Containers should run as a high UID to avoid host conflict	|We've used latest Images from the Amazon ECR Public Gallery	|
|CKV_K8S_43	|Image should use digest	|We've used latest Images from the Amazon ECR Public Gallery	|




