# How to serve an LLM with vLLM on Graviton5 CPUs on Amazon EKS Auto Mode

This sample runs large language model (LLM) inference on AWS Graviton5 (Arm64) CPUs
using the [vLLM Arm64 Deep Learning Container (DLC)](https://gallery.ecr.aws/deep-learning-containers/vllm-arm64)
on an [Amazon EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)
cluster. No GPU is required: the DLC serves an OpenAI-compatible API directly from CPU,
which is a cost-effective option for small models and low-to-moderate throughput.

[AWS Graviton5](https://aws.amazon.com/blogs/aws/now-available-amazon-ec2-m9g-and-m9gd-instances-powered-by-new-aws-graviton5-processors/)
delivers up to 25% better compute performance than Graviton4 and up to 35% faster
machine learning inference, with a 5x larger L3 cache and DDR5 memory — a good fit for
CPU-based inference.

A custom Karpenter `NodePool` constrains scheduling to Graviton5 instance families
(`m9g`/`m9gd`, generally available today; compute- and memory-optimized `c9g`/`r9g`
families are listed too and are matched as they become available in your Region).
Because the `NodePool` accepts both On-Demand and Spot capacity, you can compare the
cost of each by changing a single field in the Deployment.

The vLLM Arm64 DLC also runs on earlier Graviton generations. A Graviton3(E)- or
Graviton4-based EC2 instance (for example, `c7g`, `m7g`, `c8g`, or `r8g`) can serve the
same container — add those families to the `NodePool` `instance-family` list (and lower
the `instance-generation` bound accordingly) if you want to run on, or compare against,
earlier Graviton generations.

## Prerequisites

1. An existing Amazon EKS cluster with **EKS Auto Mode** enabled. See the
   [eksctl Auto Mode sample](../../eksctl/how-to-eks-auto-mode/) to create one.
2. The latest [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)
   and [kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html),
   configured to talk to your cluster.
3. `curl` and [`jq`](https://jqlang.github.io/jq/) on your workstation (used by the
   chat helper script).

## How it works

| File | Purpose |
|---|---|
| `nodepool-graviton.yaml` | Karpenter `NodePool` that launches Arm64 Graviton5 nodes (`m9g`/`m9gd`), labelled `NodeGroupType=Graviton` / `intent=vllm` and tainted `graviton:NoSchedule`. |
| `vllm-graviton.yaml` | `Namespace`, API-key `Secret`, vLLM `Deployment`, and a ClusterIP `Service`. |
| `multi-turn-chat.sh` | Minimal multi-turn chat client for the OpenAI-compatible API. |

### Security notes

- The vLLM server is **unauthenticated by default**. This sample injects an API key via
  `--api-key` (read from the `vllm-api-key` Secret), so every request must send
  `Authorization: Bearer <key>`.
- The `Service` is **ClusterIP only**, keeping the endpoint inside the cluster. Reach it
  from your workstation with `kubectl port-forward` (below) rather than exposing it
  publicly. Do not switch to `LoadBalancer`/`NodePort` without keeping the API key in
  place and, ideally, fronting it with a proper authentication layer.

> This sample is for testing and learning only. Always follow the
> [Amazon EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/security/docs/)
> for production clusters.

## Usage

1. Create the Graviton `NodePool`:

    ```sh
    kubectl apply -f nodepool-graviton.yaml
    ```

    ```sh
    kubectl get nodepool
    ```

2. Set a real API key. Edit `vllm-graviton.yaml` and replace the
   `change-me-to-a-long-random-token` value in the `vllm-api-key` Secret with a long
   random string, for example one generated with:

    ```sh
    openssl rand -base64 32
    ```

3. Deploy vLLM:

    ```sh
    kubectl apply -f vllm-graviton.yaml
    ```

    Karpenter provisions a right-sized Graviton node from the `NodePool`. Watch it
    appear:

    ```sh
    kubectl get nodeclaims.karpenter.sh --selector=intent=vllm
    ```

4. Wait for the model to download and load, then for the pod to become `Ready`. Cold
   start on CPU takes several minutes (image pull + node scale-up + weight load +
   compile).

    ```sh
    kubectl -n vllm get pods -l app=vllm-qwen -w
    ```

    ```sh
    kubectl -n vllm logs -f deploy/vllm-qwen
    ```

5. Port-forward the Service to your workstation:

    ```sh
    kubectl -n vllm port-forward svc/vllm-qwen 8000:8000
    ```

6. In another terminal, read the API key back and call the OpenAI-compatible API:

    ```sh
    TOKEN=$(kubectl -n vllm get secret vllm-api-key -o jsonpath='{.data.api-key}' | base64 -d)

    # Wait until the server reports healthy
    until curl -sf http://localhost:8000/health > /dev/null; do sleep 5; done

    curl -sH "Authorization: Bearer $TOKEN" http://localhost:8000/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d '{
        "model": "Qwen/Qwen3.5-2B",
        "messages": [{"role": "user", "content": "Explain generative AI to a first grader."}],
        "max_tokens": 100
      }' | jq .
    ```

7. (Optional) For an interactive, multi-turn conversation, edit `TOKEN` in
   `multi-turn-chat.sh` to match your key and run it:

    ```sh
    ./multi-turn-chat.sh
    ```

## Comparing On-Demand and Spot cost

The Deployment's `nodeSelector` pins the capacity type. Change this one field in
`vllm-graviton.yaml` and re-apply to move the workload between capacity pools:

```yaml
      nodeSelector:
        kubernetes.io/arch: arm64
        NodeGroupType: Graviton
        intent: vllm
        # on-demand  -> steady, uninterruptible capacity
        # spot       -> much cheaper, can be reclaimed with a 2-minute notice
        karpenter.sh/capacity-type: on-demand
```

```sh
kubectl apply -f vllm-graviton.yaml
```

Inspect which instance and capacity type Karpenter chose:

```sh
kubectl get nodes \
  -L karpenter.sh/nodepool \
  -L node.kubernetes.io/instance-type \
  -L topology.kubernetes.io/zone \
  -L karpenter.sh/capacity-type \
  --selector=intent=vllm
```

[`eks-node-viewer`](https://github.com/awslabs/eks-node-viewer) gives a live per-node
cost estimate, which makes the On-Demand vs Spot difference easy to see:

```sh
eks-node-viewer \
  -extra-labels karpenter.sh/nodepool,topology.kubernetes.io/zone \
  -node-selector intent=vllm
```

## CPU tuning

The DLC sets sensible CPU defaults at startup. Override any of them via the Deployment's
`env`:

| Variable | Default | Purpose |
| --- | --- | --- |
| `VLLM_CPU_KVCACHE_SPACE` | 40% of host RAM (min 2 GiB) | KV-cache size in GiB. Reserved **in addition** to the model weights and framework overhead, and must fit under the pod's memory limit. GPU memory flags such as `--gpu-memory-utilization` have no effect on CPU. |
| `VLLM_CPU_OMP_THREADS_BIND` | `nobind` | OpenMP thread binding. Set to `auto` or a core list (for example `0-31`) to pin threads. |
| `LD_PRELOAD` | `libtcmalloc_minimal.so.4` | Uses tcmalloc for lower allocator overhead. |

Use BFloat16 (`--dtype bfloat16`) weights. The CPU backend does not support GGUF models.

## Cleanup

```sh
kubectl delete -f vllm-graviton.yaml
kubectl delete -f nodepool-graviton.yaml
```

## References

- [vLLM Deep Learning Containers](https://aws.github.io/deep-learning-containers/vllm/)
- [vLLM Arm64 image on Amazon ECR Public Gallery](https://gallery.ecr.aws/deep-learning-containers/vllm-arm64)
- [Running vLLM on AWS Graviton](https://github.com/aws/aws-graviton-getting-started/blob/main/machinelearning/vllm.md)
- [Amazon EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)
