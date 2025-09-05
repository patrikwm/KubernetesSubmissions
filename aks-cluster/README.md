# Setting up AKS Cluster.

## Introduction

Since im using Azure as my cloud provider and the [MOOC](https://courses.mooc.fi/org/uh-cs/courses/devops-with-kubernetes/) course uses Google Cloud i will try to explain how to set up a similar cluster in Azure. There are some people who has set up an AKS cluster for around 14$ per week. I will try to get it as cheap as possible but still have a usable cluster.

- [Azure Cost calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [Cheap AKS Cluster](https://trstringer.com/cheap-kubernetes-in-azure/)
- [Azure naming conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

With the cheapest configuration the cost is around 388$ per month according to the calculator.

```yaml
Region: Sweden Central
Tier: Free (non-production)
OS: Linux
Instance: (B2s) 2 vCPU, 4 GB RAM 8GB Temporary Storage
Virtual Machines: 5
Managed Disks: Standard HDD 32GB
```

This totals at 159.22$ per months in the calculator. Lets see true cost after the course is done.

## Prerequisites

- Azure Subscription
- Azure CLI installed
- kubectl installed
- Helm installed
- Docker installed
- Git installed

## Steps

1. Verify Az command is installed

    ```bash
    ➜ az version
    {
    "azure-cli": "2.77.0",
    "azure-cli-core": "2.77.0",
    "azure-cli-telemetry": "1.1.0",
    "extensions": {
        "log-analytics": "1.0.0b1",
        "monitor-control-service": "1.2.0",
        "ssh": "2.0.6"
    }
    }
    ```

2. Login to Azure with azure cli. This will open an browser window where you can login with your azure credentials. Select your subscription if you have multiple. [Az login](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli?view=azure-cli-latest)

    ```bash
    az login
    ```

3. Set the subscription similar to the `gcloud config set project dwk-gke-idhere`command in gcloud.

    ```bash
    ➜ az account set --subscription "56d9a591-8bfe-40fb-96a4-17b3ec30d23a"
    ```

4. Create a resource group that will host the AKS Cluster.

    ```bash
    ➜ az group create --name rg-aks-mooc-001 --location swedencentral
    {
    "id": "/subscriptions/56d9a591-8bfe-40fb-96a4-17b3ec30d23a/resourceGroups/rg-aks-mooc-001",
    "location": "swedencentral",
    "managedBy": null,
    "name": "rg-aks-mooc-001",
    "properties": {
        "provisioningState": "Succeeded"
    },
    "tags": null,
    "type": "Microsoft.Resources/resourceGroups"
    }

5. Register the AKS resource provider if not already done.

    ```bash
    ➜ az provider register --namespace Microsoft.ContainerService
Registering is still on-going. You can monitor using 'az provider show -n Microsoft.ContainerService'
    ```

5. Create a AKS Cluster. (This will take couple of minutes to complete)

    ```bash
    ➜ az aks create \
        --resource-group rg-aks-mooc-001 \
        --name dwk-cluster \
        --location swedencentral \
        --node-count 5 \
        --node-vm-size Standard_B2s \
        --node-osdisk-size 32 \
        --node-osdisk-type Managed \
        --os-sku Ubuntu \
        --kubernetes-version 1.32.0 \
        --tier free \
        --ssh-key-value ~/.ssh/id_rsa.pub
    ```

6. Get the credentials for the cluster to be able to use kubectl.

    ```bash
    ➜ az aks get-credentials --resource-group rg-aks-mooc-001 --name dwk-cluster
    Merged "dwk-cluster" as current context in /Users/patrik/.kube/config
    ```

7. Change the cluster to dwk-cluster if not already set.

    ```bash
    ➜ kubectx dwk-cluster
    Switched to context "dwk-cluster".
    ```

8. get cluster information.

   ```bash
    k cluster-info
    Kubernetes control plane is running at https://dwk-cluste-rg-aks-mooc-001-56d9a5-wuxh45te.hcp.swedencentral.azmk8s.io:443
    CoreDNS is running at https://dwk-cluste-rg-aks-mooc-001-56d9a5-wuxh45te.hcp.swedencentral.azmk8s.io:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
    Metrics-server is running at https://dwk-cluste-rg-aks-mooc-001-56d9a5-wuxh45te.hcp.swedencentral.azmk8s.io:443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
    ```

9. Apply the deployment from kubernetes-hy repository. I downloaded it to aks-cluster/manifests/deployment.yaml

    ```bash
    ➜ curl -L \
        https://raw.githubusercontent.com/kubernetes-hy/material-example/e11a700350aede132b62d3b5fd63c05d6b976394/app6/manifests/deployment.yaml \
        -o aks-cluster/manifests/deployment.yaml
    ➜ kubectl apply -f aks-cluster/manifests/deployment.yaml
    deployment.apps/hello-world created
    ```

10. Check that the deployment is running.

    ```bash
    ➜ kubectl get svc seedimage-svc --watch
    Found existing alias for "kubectl". You should use: "k"
    NAME            TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
    seedimage-svc   LoadBalancer   10.0.114.153   4.225.130.31   80:32114/TCP   67s
    ```

11. Delete the AKS cluster.

    ```bash
    ➜ az aks delete \
        --resource-group rg-aks-mooc-001 \
        --name dwk-cluster \
        --yes \
        --no-wait
    ```