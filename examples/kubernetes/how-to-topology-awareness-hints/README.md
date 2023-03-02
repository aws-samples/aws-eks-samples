# How to implement topology aware hints on a Service inside EKS cluster
A tutorial on implementing topology aware routing for the endpoints in a service inside EKS Cluster

## Prerequisites
1. Existing EKS cluster with managed nodegroup consisting of nodes spread across multiple AZ's
2. Install kubectl
3. Install latest aws-cli.<br>

## Getting Started
1. Create a new namespace <br>
````kubectl apply -f https://raw.githubusercontent.com/Manyamteja/EKS_samples/main/demo-namespace.yaml````

2. Ensure that your worker nodes are spread across 2 availability zones.
3. Create a sample Nginx deployment using the following command which has 3 replicas<br>
````kubectl apply -f https://raw.githubusercontent.com/Manyamteja/EKS_samples/main/demo-nginx-deployment.yaml ````
4. Now, expose the pods using a service<br>
````kubectl apply -f https://raw.githubusercontent.com/Manyamteja/EKS_samples/main/service-demo-nginx.yaml````
5. Kubernetes service object will be created and the endpointSlice controller will create endpoint slice automatically. <br>
````kubectl get service -n demo```` <br>
````kubectl get endpointslices -n demo````<br>
6. Verify if the Hints are populated inside the endpointSlice <br>
````kubectl get endpointslices <nginx-xxxx> -n demo -oyaml````
7. You should notice the Hints being populated for all the endpoints inside the endpointSlice
8. If you are not seeing the Hints populated, then check the kube-proxy logs if any errors posted. <br>
````kubectl -n kube-system logs <kube-proxy-xxxx>```` <br>

If you see any messages like below then it means that kube-proxy skipped to apply the topology aware hints.<br>
````Skipping topology aware endpoint filtering since no hints were provided for zone" zone="eu-west-1b"````<br>
<br>
This can happen due to multiple reasons as whenever any of the Safegaurds are not satisfied or if kube-proxy sees Constraints listed under K8s documentation. <br>
Safeguards: https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/#safeguards <br>
Constraints: https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/#constraints <br>

<br>
Topology Hints are only populated when there are no Contrains effecting and all the Safeguards applied before the kube-proxy starts decides to start using it even if you gave the annotation. <br>
