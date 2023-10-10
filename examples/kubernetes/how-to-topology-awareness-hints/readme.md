<p></p>
<p></p>
<h2>
Background:</span></h2>

<p class="MsoNormal" style="text-align:justify">Whenever you create an Kubernetes cluster there will be an endpoint slice controller running which will be checking for any services and the pods that are running based on which the endpointSlices will be created. These endpoint slices consists of all
    the pods that are running. </p>

<p class="MsoNormal" style="text-align:justify">Generally, EKS worker nodes will be spanned over multiple AZs and the pods deployed also will be spread across these nodes in different AZs. Any traffic that is coming will be distributed to these pods randomly based on the Iptables that the kube-proxy
    manages. </p>

<p class="MsoNormal" style="text-align:justify">In a multi-AZ cluster, traffic is more likely to go to endpoints that are in the other AZs even though in-zone endpoints are available. With this TopologyAwareHints feature Kube-proxy can make intelligent decisions based on the zone hints by modifying
    the probabilities for routing traffic to the endpoints routing in KUBE-SERVICE chain. </p>

<h2><span style="mso-fareast-language:EN-GB">Advantages:</span></h2>
<p class="MsoNormal">This can enhance the performance of the application reducing the latency by keeping the traffic route in-zone available endpoints as much as possible. </p>
<p class="MsoNormal">This can also effectively make the cost savings by limiting the inter-AZ data transfers. </p>
<p class="MsoNormal"><span style="mso-no-proof:yes"></span></p>
<p>

</p>
<h2><span style="mso-fareast-language:EN-GB">How it Works:</span></h2>
<p class="MsoNormal">Enabling this feature is very simple that you need to add annotation <code><span style="font-size:10.0pt;mso-fareast-font-family:&quot;Times New Roman&quot;;
mso-fareast-theme-font:major-fareast">service.kubernetes.io/topology-aware-hints:auto </span></code>in the service manifest and then the EndpointSlice Contoller will set the hints only if no contraints and all safeguards are met.</p>
<h2><span style="mso-fareast-language:EN-GB">Workflow:</span></h2>
<p class="MsoNormal">Once you deploy a service by enabling this feature EndpointSlice controller will try to set the hints based on the AZ and distribute the&nbsp;allocation of Endpoints.</p>
<p class="MsoNormal">EndpointSlice controller will identify the endpoint’s pods zone based on the node’s label <code><span style="font-size:10.0pt;mso-fareast-font-family:
&quot;Times New Roman&quot;;mso-fareast-theme-font:major-fareast">topology.kubernetes.io/zone
</span></code>it is scheduled on. In EKS you will see this label being set automatically when the node is created.</p>

<pre class="MsoNormal">kubectl get nodes -L <a href="http://topology.kubernetes.io/zone" target="_blank">topology.kubernetes.io/zone
</a></pre>
<p class="MsoNormal">EndpointSlice controller makes the allocation of the endpoints based on the allocatable CPU cores for the nodes that are running in that zone. </p>
<h3>For Example:
</h3>
<p class="MsoNormal">You have cluster with worker nodes spread across 2 Az’s and with following number of vCPU's in each zone <br></p>

<p class="MsoNormal">    Zone 1a: 12 vCPU  Zone 1b: 4vCPU

<p>In the above case when allocating the endpoints, controller will try to make the distribution in a proportional way to number of CPU cores that 75% will be distributed to zone-1a and 25% to zone-1b. When same-zone endpoints are exhausted, endpoints will
    be taken  from zones that have excess capacity.</p>
<p>If a service had 4 endpoints then endpointSlice controller will attempt to allocate 3 endpoints to zone 1a and 1 endpoint will to 1b.
</p>

<h2>Overhead Threshold</h2>
<p>This feature of topology aware routing for traffic inside cluster is designed based on heuristic
</p>
<table class="MsoTableGrid" style="border-collapse:collapse;border:none;mso-border-alt:solid windowtext .5pt;
 mso-yfti-tbllook:1184;mso-padding-alt:0cm 5.4pt 0cm 5.4pt" cellspacing="0" cellpadding="0" border="1">
    <tbody>
        <tr style="mso-yfti-irow:0;mso-yfti-firstrow:yes;mso-yfti-lastrow:yes">
            <td style="width:113.15pt;border:solid windowtext 1.0pt;
  mso-border-alt:solid windowtext .5pt;padding:0cm 5.4pt 0cm 5.4pt" width="151" valign="top">
                <p class="MsoNormal">ProportionalByCore</p>
            </td>
            <td style="width:337.65pt;border:solid windowtext 1.0pt;
  border-left:none;mso-border-left-alt:solid windowtext .5pt;mso-border-alt:
  solid windowtext .5pt;padding:0cm 5.4pt 0cm 5.4pt" width="450" valign="top">
                <p class="MsoNormal">Endpoints will be allocated to each zone proportionally, based on the allocatable Node CPU cores in each zone.</p>
            </td>
        </tr>
    </tbody>
</table>
<p>

</p>
<p>When there is a situation where kube-proxy finds it is not able possible to distribute the endpoints proportional to the CPU cores as in the above scenario then it will check if there is any zone that is exceeding threshold of 20% overload. Kube-proxy
    will apply the hints only when this overload threshold is below 20%.</p>
<h3>Example:
</h3>
<p class="MsoNormal">In a 3-zone cluster where each zone has an equivalent CPU size, an EndpointSlice for a 4 endpoint service would not receive any zone hints.</p>
<p>The expected number of endpoints per zone would be 1.33, and 2 of the 3 zones would only have 1 endpoint allocated.</p>
<p>This means that endpoints for these zones would be likely to receive 33% more traffic than a perfectly balanced scenario. In this case, the "Overload" for those zones would be 33%.</p>
<p>As the threshold is more than 20% which is accepted Hints will not be added for a Service.</p>
<p></p>
<p></p>
<h2>Node updates:
</h2>
<p></p>
<p></p>
<p>

</p>
<p class="MsoNormal"><span style="mso-fareast-language:EN-US">When there is a
node update or cluster autoscaling either scaling in/out the nodes, these endpoints
should be again redistributed proportional to the new allocatable CPU cores available in
that zone. This results in to check for the overhead threshold again and make
changes if necessary.</span></p>
<p><span style="mso-fareast-language:EN-US">For example:
Consider an example where you have 4 nodes in 4 AZs each having 10vCpus and the
service having 4 endpoints.</span></p>
<p><span style="mso-fareast-language:EN-US">Each
zone will get 25% of endpoints allocated</span>
</p>
<table class="MsoTableGrid" style="border-collapse:collapse;border:none;mso-border-alt:solid windowtext .5pt;
 mso-yfti-tbllook:1184;mso-padding-alt:0cm 5.4pt 0cm 5.4pt" cellspacing="0" cellpadding="0" border="1">
    <tbody>
        <tr style="mso-yfti-irow:0;mso-yfti-firstrow:yes">
            <td style="width:112.7pt;border:solid windowtext 1.0pt;
  mso-border-alt:solid windowtext .5pt;padding:0cm 5.4pt 0cm 5.4pt" width="150" valign="top">
                <p class="MsoNormal"><span style="mso-fareast-language:EN-US">Zone-1a</span></p>
            </td>
            <td style="width:112.7pt;border:solid windowtext 1.0pt;
  border-left:none;mso-border-left-alt:solid windowtext .5pt;mso-border-alt:
  solid windowtext .5pt;padding:0cm 5.4pt 0cm 5.4pt" width="150" valign="top">
                <p class="MsoNormal"><span style="mso-fareast-language:EN-US">Zone-1b</span></p>
            </td>
            <td style="width:112.7pt;border:solid windowtext 1.0pt;
  border-left:none;mso-border-left-alt:solid windowtext .5pt;mso-border-alt:
  solid windowtext .5pt;padding:0cm 5.4pt 0cm 5.4pt" width="150" valign="top">
                <p class="MsoNormal"><span style="mso-fareast-language:EN-US">Zone-1c</span></p>
            </td>
            <td style="width:112.7pt;border:solid windowtext 1.0pt;
  border-left:none;mso-border-left-alt:solid windowtext .5pt;mso-border-alt:
  solid windowtext .5pt;padding:0cm 5.4pt 0cm 5.4pt" width="150" valign="top">
                <p class="MsoNormal"><span style="mso-fareast-language:EN-US">Zone-1d</span></p>
            </td>
        </tr>
        <tr style="mso-yfti-irow:1;mso-yfti-lastrow:yes">
            <td style="width:112.7pt;border:solid windowtext 1.0pt;
  border-top:none;mso-border-top-alt:solid windowtext .5pt;mso-border-alt:solid windowtext .5pt;
  padding:0cm 5.4pt 0cm 5.4pt" width="150" valign="top">
                <p class="MsoNormal"><span style="mso-fareast-language:EN-US">25%</span></p>
            </td>
            <td style="width:112.7pt;border-top:none;border-left:
  none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;
  mso-border-top-alt:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;
  mso-border-alt:solid windowtext .5pt;padding:0cm 5.4pt 0cm 5.4pt" width="150" valign="top">
                <p class="MsoNormal"><span style="mso-fareast-language:EN-US">25%</span></p>
            </td>
            <td style="width:112.7pt;border-top:none;border-left:
  none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;
  mso-border-top-alt:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;
  mso-border-alt:solid windowtext .5pt;padding:0cm 5.4pt 0cm 5.4pt" width="150" valign="top">
                <p class="MsoNormal"><span style="mso-fareast-language:EN-US">25%</span></p>
            </td>
            <td style="width:112.7pt;border-top:none;border-left:
  none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;
  mso-border-top-alt:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;
  mso-border-alt:solid windowtext .5pt;padding:0cm 5.4pt 0cm 5.4pt" width="150" valign="top">
                <p class="MsoNormal"><span style="mso-fareast-language:EN-US">25%</span></p>
            </td>
        </tr>
    </tbody>
</table>
<p>

</p>
<p>In this case 4 endpoints can be distributed equally each zone getting 1 endpoint. Now the node in zone-1d was dropped due to some reason which makes the kubelet to schedule it to any other node.</p>
<p class="MsoNormal">Consider it scheduled on node in zone-1a. This will trigger the proportion of endpoints that should be allocated to each zone to change.</p>

<p class="MsoNormal">Cluster is now having nodes across 3 Az’s and service with 4 endpoints in which the proportional distribution based on vCPU cores is impossible to happen and one zone will get atleast 2 endpoints. Resulting in the breach to overhead threshold and kube-proxy
    will skip implementing the Hints.</p>
<h2 class="MsoNormal">Caveats:</h2>
<p class="MsoNormal"><span style="mso-bidi-font-family:Calibri;mso-bidi-theme-font:minor-latin"><span style="mso-list:Ignore">1.<span style="font:7.0pt &quot;Times New Roman&quot;">&nbsp;&nbsp;&nbsp;&nbsp;
</span></span>
    </span>This approach is based on the assumption that traffic inside the cluster is same across the Az’s, if the traffic to the endpoints is only arising from a single subset of Az then this can result in excess load to the endpoints in that zone only.</p>
<p class="MsoNormal">2. This can also be affected by Horizontal Pod Autoscalers (HPA)<br></p>
    <p class="MsoNormal">3. May not be suitable when the cluster is having more scaling activity like cluster autoscaler making changes to the desired size frequently or when the workloads are scheduled on spot instances as these can be interrupted anytime which can make
        it
        <span style="font-family:
&quot;Calibri&quot;,sans-serif;mso-ascii-theme-font:minor-latin;mso-hansi-theme-font:
minor-latin;mso-bidi-font-family:&quot;Times New Roman&quot;;mso-bidi-theme-font:minor-bidi">impossible
to achieve balanced allocation and exceed the overhead threshold. Nevertheless,
this will not make any disruptions as the kube-proxy just ignores to apply
these Hints.</span></p>
    <p class="MsoNormal"><span style="font-family:
&quot;Calibri&quot;,sans-serif;mso-ascii-theme-font:minor-latin;mso-hansi-theme-font:
minor-latin;mso-bidi-font-family:&quot;Times New Roman&quot;;mso-bidi-theme-font:minor-bidi">4. Applying these Hints can be skipped by kube-proxy at times where there are any pod assignment constraints such as Affinity/Anti-affinity etc. where the redistribution of endpoints cannot be made.<br></span></p>
    <p class="MsoNormal"><span style="font-family:
&quot;Calibri&quot;,sans-serif;mso-ascii-theme-font:minor-latin;mso-hansi-theme-font:
minor-latin;mso-bidi-font-family:&quot;Times New Roman&quot;;mso-bidi-theme-font:minor-bidi">5. This feature also considers any Fargate nodes as similar to regular EC2 nodes when calculating the Overhead Threshold.<br></span></p>
    <p class="MsoNormal"><span style="font-family:
&quot;Calibri&quot;,sans-serif;mso-ascii-theme-font:minor-latin;mso-hansi-theme-font:
minor-latin;mso-bidi-font-family:&quot;Times New Roman&quot;;mso-bidi-theme-font:minor-bidi"><br></span>There are some Safeguards and Constraints under which kube-proxy decides skip these topology hints to implements</p>
    <p class="MsoNormal">Safeguards: <a href="https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/#safeguards">https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/#safeguards</a>
    <p class="MsoNormal">Constraints: <a href="https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/#constraints">https://kubernetes.io/docs/concepts/services-networking/topology-aware-hints/#constraints</a>

</span>
    </p>
    <h1>Demo:<br></h1>
    <p><span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif;mso-fareast-font-family:
&quot;Times New Roman&quot;;mso-ansi-language:EN-IE;mso-fareast-language:EN-GB;
mso-bidi-language:AR-SA">1. Create an EKS cluster and worker nodes with nodes across 3 Az's. </span></p>
    <p><span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif;mso-fareast-font-family:
&quot;Times New Roman&quot;;mso-ansi-language:EN-IE;mso-fareast-language:EN-GB;
mso-bidi-language:AR-SA">2. Clone into this repository using git clone</span></p><pre><span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif;mso-fareast-font-family:
&quot;Times New Roman&quot;;mso-ansi-language:EN-IE;mso-fareast-language:EN-GB;
mso-bidi-language:AR-SA">git clone <br></span></pre>
    <p><span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif;mso-fareast-font-family:
&quot;Times New Roman&quot;;mso-ansi-language:EN-IE;mso-fareast-language:EN-GB;
mso-bidi-language:AR-SA">3. Apply the manifests in this repository, this will create the namespace, deployment using the Busybox image and a service exposing the deployment</span></p>
    <pre><span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif;mso-fareast-font-family:
&quot;Times New Roman&quot;;mso-ansi-language:EN-IE;mso-fareast-language:EN-GB;
mso-bidi-language:AR-SA">kubectl apply -f .<span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif;mso-fareast-font-family:
&quot;Times New Roman&quot;;mso-ansi-language:EN-IE;mso-fareast-language:EN-GB;
mso-bidi-language:AR-SA"><br></span></pre>4. Note that the service "service-demo-Busybox" is deployed as service type ClusterIP adding the annotation
    <p></p><pre> service.kubernetes.io/topology-aware-hints: auto</pre>
    <p></p><pre>#you can use the below command to verify the service<br></span>kubectl get service demo-service -n demo -o yaml</pre>
    <p></p>
    <p>5. Verify if the Hints are being populated inside the endpoint slice.</p><pre>kubectl get endpointslices.discovery.k8s.io &lt;endpoint-name&gt; -n demo -oyaml</pre>
    <p>6. You will be able to see hints being populated as below.</p>
    <p></p><br><pre tabindex="0" style="background-color:#f8f8f8;-moz-tab-size:4;-o-tab-size:4;tab-size:4">&nbsp;&nbsp;&nbsp; zone: eu-west-1a<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; uid: 1df689f2-65db-47a9-90c7-0dd4b4d0a544<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; namespace: demo<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; name: busybox-demo-7fbc66c54b-mkf4k<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; kind: Pod<br>&nbsp;&nbsp;&nbsp; targetRef:<br>&nbsp;&nbsp;&nbsp; nodeName: ip-10-0-12-200.eu-west-1.compute.internal<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - name: eu-west-1a<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; forZones:<br>&nbsp;&nbsp;&nbsp; hints:<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; terminating: false<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; serving: true<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ready: true<br>&nbsp;&nbsp;&nbsp; conditions:<br>&nbsp;&nbsp;&nbsp; - 10.0.2.150<br>&nbsp; - addresses:<br>&nbsp; endpoints:<br>&nbsp; apiVersion: discovery.k8s.io/v1<br>- addressType: IPv4<code class="language-yaml" data-lang="yaml"><span style="display:flex"><span><span style="color:green;font-weight:700"></span></span></span><span style="display:flex"><span><span style="color:#bbb"><br></span></span></span></code></pre>
    <p>6. Scale the deployment to 4 replicas and then check for the hints in endpoint slices<br></p><pre>kubectl -n demo scale deployments busybox-demo --replicas=4</pre>
    <p>7. You can observe that the Hints being removed as it is impossible to achieve even distribution and also the overhead threshold breaches as explained above.</p>
    <p>8. Verify the kube-proxy pod logs if it says kube-proxy skipped applying Hints</p><pre>kubectl -n kube-system logs kube-proxy-xxxx<br></pre><pre>I0228 11:05:14.404568&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 1 proxier.go:853] "Syncing iptables rules"<br>I0228 11:05:14.431451&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 1 topology.go:168] "Skipping topology aware endpoint filtering since one or more endpoints is missing a zone hint"<br>I0228 11:05:14.431530&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 1 proxier.go:1464] "Reloading service iptables data" numServices=12 numEndpoints=17 numFilterChains=4 numFilterRules=4 numNATChains=32 numNATRules=67<br>I0228 11:05:14.435518&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 1 proxier.go:820] "SyncProxyRules complete" elapsed="31.008873ms"</pre>
    <h1>Test:</h1>
    <p>1. In a working scenario, where the Hints are populated inside the endpointSlice.</p>
    <p>2. Deploy a test pod in all the availability zones inside your cluster to curl the service and see to which pod the traffic is being directed to.</p>
    <p>3. You can use "nicolaka/netshoot" image in test pod to curl the service. Replace the &lt;node-name&gt; in below command.<br></p>
    <p> </p><pre>&nbsp;kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot --overrides='{"spec": { "nodeSelector": {"kubernetes.io/hostname": "&lt;node-name&gt;"}}}'</pre>
    <p>4. Once you are inside the pod use curl command to hit the service </p><pre>curl &lt;service-ClusterIP&gt;:80</pre>
    <p>5. The above sample deployment will return the output of PodName and the nodeName on which it is scheduled as below<br></p><pre><html><body><h4>PodName:busybox-demo-7b7b9bf455-c27z9
HTTP/1.1 200 OK
NodeName:ip-10-0-9-45.eu-west-1.compute.internal
HTTP/1.1 200 OK
podIP:10.0.11.140</h4></body></html></pre>
    <p>6. From the above output you can verify whether the traffic is being forwarded to the pods from same Az </p>
    <p>7. Take the nodeName from the output, use the following command which will return you the zone of that node and you can verify if it aligns with the zone in which your test pod is deployed <br></p><pre> kubectl get nodes &lt;node-name&gt;&nbsp; -L topology.kubernetes.io/zone<br></pre>
    <p></p>
