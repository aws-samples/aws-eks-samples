# How to Enable Proxy protocol for NGINX Ingress Controller with CLB in EKS

#### Common Use Case: 
*Customer wants to receive the client connection (real IP address) information passed through the load balancer to Pods running in EKS Cluster*.

Example Architecture:
```
CLB ---> Node ---> backend App Pod (nginx appserver)
```

## Pre-requisite
* Install latest [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
* An existing AWS EKS Cluster.
* Install NGINX ingress controller as [here](https://kubernetes.github.io/ingress-nginx/deploy/#quick-start).

---
## Below are the steps to be followed for enabling proxy in Classic Load Balancer (CLB).

1. Enable proxy protocol support in CLB. Refer to [documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html).

### To enable proxy protocol for your load balancer:
Create a policy for the loadbalancer that can be applied to a listener port.
~~~
aws elb create-load-balancer-policy —load-balancer-name my-loadbalancer —policy-name my-ProxyProtocol-policy —policy-type-name ProxyProtocolPolicyType —policy-attributes AttributeName=ProxyProtocol,AttributeValue=true
~~~

Then, Run below command to enable the newly created policy on the specified instance port mapped with listener port 80 and 443.

~~~
aws elb set-load-balancer-policies-for-backend-server —load-balancer-name my-loadbalancer —instance-port <instance_port> —policy-names my-ProxyProtocol-policy
~~~
*Replace `<instance_port>` with the ports mapped to your CLB listeners on port 80 and/or 443*

### Verify that proxy protocol is enabled using below
~~~
aws elb describe-load-balancers —load-balancer-name my-loadbalancer
~~~

Example output:
~~~
"BackendServerDescriptions": [
        {
          “InstancePort”: 32486,
          “PolicyNames”: [
            “my-ProxyProtocol-policy”
          ]
        },
        {
          “InstancePort”: 32729,
          “PolicyNames”: [
            “my-ProxyProtocol-policy”
          ]
        }
      ],
~~~
*Note*: Instance port is the randomly generated port mapped with listener 80 and 443.


2. Added below annotation in nginx ingress controller configMap and restart the controller pods.
~~~
kubectl edit cm ingress-nginx-controller -n ingress-nginx
~~~
*Add the parameters below into the data section of the configmap*

```
use-forwarded-headers: "true"
compute-full-forwarded-for: "true"
use-proxy-protocol: "true"  
forwarded-for-header: "X-Forwarded-For"

```

3. Deploy the sample deployment with nginx pod.
```
kubectl create -f nginx-app.yaml
```

4. Create the service to expose the deployment pod.
```
kubectl create -f nginx-svc.yml
```

5. Create nginx ingress object using below manifest.
```
kubectl create -f nginx-ingress.yml
```

6. Tested using load balancer DNS name and can see the result below
~~~

curl http://a47974c475b84429caa06f9fc12635a9-635731211.ap-southeast-1.elb.amazonaws.com/ 


<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
~~~

7. Verify the setup by checking logs from both the nginx controller pod and backend app pod
   
Logs of nginx controller pod.

```
kubectl logs ingress-nginx-controller-5869689b64-kspb5 -n ingress-nginx
```
Example output:
~~~

...
60.103.221.213 - - [15/Feb/2023:13:17:07 +0000] "GET /phpmyAdmin/index.php?lang=en HTTP/1.1" 404 555 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" 215 0.001 [default-nginx-svc-8080] [] 192.168.0.239:80 555 0.000 404 3d7a0e9abec004040e6c7b7e9930d947
220.158.159.170 - - [15/Feb/2023:13:18:05 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/7.86.0" 139 0.000 [default-nginx-svc-8080] [] 192.168.0.239:80 615 0.001 200 0bbae2c4d273418ae7bfd61456b736f5
220.158.159.170 - - [15/Feb/2023:13:18:15 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/7.86.0" 139 0.000 [default-nginx-svc-8080] [] 192.168.0.239:80 615 0.001 200 06cdc8879f007ff085f9ff528417a0f1
~~~

Logs from backend app pod

```
kubectl logs nginx-deploy-6cff5c6db-xc9kk
```
Example output:
~~~
...
192.168.0.235 - - [15/Feb/2023:13:17:07 +0000] "GET /phpmyAdmin/index.php?lang=en HTTP/1.1" 404 555 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" "60.103.221.213"
192.168.0.235 - - [15/Feb/2023:13:18:05 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/7.86.0" "220.158.159.170"
192.168.0.235 - - [15/Feb/2023:13:18:15 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/7.86.0" "220.158.159.170"
~~~


## Clean Up

```
kubectl delete -f nginx-ingress.yml

kubectl delete -f nginx-svc.yml

kubectl delete -f nginx-app.yaml

```
