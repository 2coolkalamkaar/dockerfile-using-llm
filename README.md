# Dockerfile Generator using LLM

This project sets up [Ollama](https://ollama.ai/) in a Kubernetes cluster using a Persistent Volume Claim (PVC) backed by the Local Path Provisioner. It deploys a custom LLM model named `docker-generator` (based on `llama3.1`) that strictly generates production-ready Dockerfiles tailored to the specific programming language you request.

## Architecture

- **Local Path Provisioner**: Provisions local node storage for persistent model caching.
- **Ollama Models PVC (10Gi)**: Claims host storage to keep models downloaded, so restarting the pod doesn't require re-downloading.
- **ConfigMap (`ollama-modelfile`)**: Contains the `Modelfile` with system instructions and a startup script (`init.sh`) to automatically pull the `llama3.1` model and create the `docker-generator` custom model.
- **Deployment & Service**: Deploys Ollama in Kubernetes and exposes it on port 11434.

## Prerequisites

- A running Kubernetes cluster.
- `kubectl` configured and connected to your cluster.

## Step 1: Install the Local Path Provisioner

Run this command on your master node (if not already installed). This creates a StorageClass called `local-path` that will automatically manage folders in `/opt/local-path-provisioner` on your VM.

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

## Step 2: Create the PVC

The `pvc.yaml` file is the "contract" that asks the cluster for 10GB of space for your models. Apply both the PVC and the Ollama configuration to your cluster:

```bash
kubectl apply -f pvc.yaml
kubectl apply -f 02-ollama.yaml
```

Check the status to ensure the PVC is bound and the Pod is running:

```bash
kubectl get pvc,pod -l app=ollama
```

## Step 3: Generate a Dockerfile

To generate a Dockerfile for a specific language (e.g., Python), run this from your terminal where `kubectl` is configured:

```bash
# Target the deployment, Kubernetes will pick the running Pod for you
kubectl exec -it deployment/ollama -- ollama run docker-generator "Python"
```

### 🛠️ How it works:
- `kubectl exec -it`: This opens an interactive terminal session inside the container.
- `deployment/ollama`: Instead of finding the exact Pod name (like `ollama-7d9f8c...`), you can just target the deployment. Kubernetes will pick the running Pod for you.
- `ollama run docker-generator`: This calls the custom model we defined in your ConfigMap.
- `"Python"`: This is the prompt. Since your `Modelfile` has the instructions, the model sees "Python" and knows exactly what to do based on the system prompt.
# dockerfile-using-llm
# dockerfile-using-llm
