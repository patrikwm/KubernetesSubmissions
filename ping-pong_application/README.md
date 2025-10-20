# Chapter 4

# Exercise: 3.3. To the Gateway

- To use gateway with AKS you can use either managed NGINX or Application Load Balancer (ALB) from Azure.
- ALB is more complex to set up but has more features and better integration with Azure.
- [Application gateway for containers](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller?tabs=install-helm-windows)


## ALB Ingress Controller

Create a cluste rwith the setup-aks-cluster.sh script:

*I have removed the cluster specific output*

```bash
➜ ./script/setup-aks-cluster.sh create
Creating AKS cluster dwk-cluster in resource group rg-aks-mooc-001...
Cluster created successfully! Now logging in to it...
A different object named dwk-cluster already exists in your kubeconfig file.
Overwrite? (y/n): y
A different object named clusterUser_rg-aks-mooc-001_dwk-cluster already exists in your kubeconfig file.
Overwrite? (y/n): y
Merged "dwk-cluster" as current context in /Users/patrik/.kube/config
Creating identity azure-alb-identity in resource group rg-aks-mooc-001
Waiting 60 seconds to allow for replication of the identity...
Apply Reader role to the AKS managed cluster resource group for the newly provisioned identity
Set up federation with AKS OIDC issuer
Installing Gateway API CRDs first...
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/grpcroutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/referencegrants.gateway.networking.k8s.io created
Installing ALB Controller...
Pulled: mcr.microsoft.com/application-lb/charts/alb-controller:1.0.0
Digest: sha256:635a3bdf648c2e003b1cdde945ba24e794310e279e08f496f31975c721259f31
NAME: alb-controller
LAST DEPLOYED: Thu Oct 16 14:27:40 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Congratulations! The ALB Controller has been installed in your Kubernetes cluster!
Verifying ALB Controller installation...
Waiting for ALB Controller pods to be ready...
error: no matching resources found
Checking ALB Controller pods:
NAME                                       READY   STATUS     RESTARTS   AGE
alb-controller-6fc8cdf558-qkg6j            0/1     Init:0/1   0          1s
alb-controller-bootstrap-78bcf5985-78g8b   0/1     Init:0/1   0          1s
Verifying GatewayClass azure-alb-external:
Error from server (NotFound): gatewayclasses.gateway.networking.k8s.io "azure-alb-external" not found
```

Seems that the script does not wait long enough for the ALB controller to be fully ready. Running the commands again after a short wait should show that everything is working:

```bash
➜ kubectl get gatewayclass azure-alb-external -o yaml
Found existing alias for "kubectl". You should use: "k"
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  creationTimestamp: "2025-10-16T12:28:00Z"
  generation: 1
  name: azure-alb-external
  resourceVersion: "3358"
  uid: bf596881-89b0-4b7c-8ea0-0e38a5fecc87
spec:
  controllerName: alb.networking.azure.io/alb-controller
status:
  conditions:
  - lastTransitionTime: "2025-10-16T12:28:20Z"
    message: Valid GatewayClass
    observedGeneration: 1
    reason: Accepted
    status: "True"
    type: Accepted
```

Before deploying ping-pong app i need to deploy the postgres database:

```bash
➜ ./script/postgres.sh apply
Applying postgres resources to namespace database...
namespace/database created
secret/postgres-secrets created
service/postgres-svc created
statefulset.apps/postgres-stset created
➜ k get pods
NAME               READY   STATUS    RESTARTS   AGE
postgres-stset-0   1/1     Running   0          87s
```

Next lets enable the approuting for ingress to work
```bash
az aks approuting enable --resource-group rg-aks-mooc-001 --name dwk-cluster
```

next lets deploy the ping-pong application:

```bash
➜ ./script/ping-pong.sh apply
Applying resources to namespace exercises...
namespace/exercises created
secret/ping-pong-secrets created
configmap/ping-pong-config created
deployment.apps/ping-pong-deployment created
service/ping-pong-svc created
ingress.networking.k8s.io/ping-pong-ingress created
➜ k get pods
NAME                                   READY   STATUS    RESTARTS   AGE
ping-pong-deployment-d4d995fbc-ptwfc   1/1     Running   0          4m12s
```

Verify that the application is working through the ingress:

```bash
➜ k get ingress
NAME                CLASS                                HOSTS   ADDRESS          PORTS   AGE
ping-pong-ingress   webapprouting.kubernetes.azure.com   *       135.116.216.52   80      19m
➜ curl http://135.116.216.52/pingpong
{"message":"pong 0","counter":0,"storage":"database"}%
➜ curl http://135.116.216.52/pingpong
{"message":"pong 1","counter":1,"storage":"database"}%
```

Lets change the service to use ClusterIP instead of NodePort as the ALB controller does not support NodePort but the ingress supports both.

```bash
➜ k get service
NAME            TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
ping-pong-svc   NodePort   10.0.109.120   <none>        80:32044/TCP   28m
➜ k apply -f ping-pong_application/manifests/service.yaml
service/ping-pong-svc configured
➜ k get service
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
ping-pong-svc   ClusterIP   10.0.109.120   <none>        80/TCP    29m
➜ curl http://135.116.216.52/pingpong
{"message":"pong 2","counter":2,"storage":"database"}%
```

To use this GatewayClass i will deploy a Gateway and HTTPRoute for the ping-pong app.

```bash
➜ k apply -f ping-pong_application/manifests/gateway.yml
gateway.gateway.networking.k8s.io/my-gateway configured
➜ k apply -f ping-pong_application/manifests/route.yml
httproute.gateway.networking.k8s.io/my-route created
```

Seems im missing an annotation on the gateway to link it to the Application Gateway for Containers resource. I will add that to the gateway manifest and reapply it.


```bash
➜ k get gateway
NAME         CLASS                ADDRESS   PROGRAMMED   AGE
my-gateway   azure-alb-external                          7m4s
➜ k describe gateway
Name:         my-gateway
Namespace:    exercises
Labels:       <none>
Annotations:  <none>
API Version:  gateway.networking.k8s.io/v1
Kind:         Gateway
Metadata:
  Creation Timestamp:  2025-10-16T13:23:15Z
  Generation:          1
  Resource Version:    21795
  UID:                 15dc8f69-8ccb-4b01-b063-34cf9232f13a
Spec:
  Gateway Class Name:  azure-alb-external
  Listeners:
    Allowed Routes:
      Kinds:
        Group:  gateway.networking.k8s.io
        Kind:   HTTPRoute
      Namespaces:
        From:  Same
    Name:      http
    Port:      80
    Protocol:  HTTP
Status:
  Conditions:
    Last Transition Time:  2025-10-16T13:23:15Z
    Message:               Gateway does not have annotation to reference Application Gateway for Containers resource
    Observed Generation:   1
    Reason:                Accepted
    Status:                False
    Type:                  Accepted
Events:                    <none>
➜ KubernetesSubmissions ⚡( 52-exercise-33-to-the-gateway)                                                       26 hours ago
▶
```

Im obviously missing something as the gateway is not being programmed. [Create Application Gateway for Containers managed by ALB Controller](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-managed-by-alb-controller?tabs=new-subnet-aks-vnet)


```bash
AKS_NAME='dwk-cluster'
RESOURCE_GROUP='rg-aks-mooc-001'

MC_RESOURCE_GROUP=$(az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP --query "nodeResourceGroup" -o tsv)
CLUSTER_SUBNET_ID=$(az vmss list --resource-group $MC_RESOURCE_GROUP --query '[0].virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id' -o tsv)
read -d '' VNET_NAME VNET_RESOURCE_GROUP VNET_ID <<< $(az network vnet show --ids $CLUSTER_SUBNET_ID --query '[name, resourceGroup, id]' -o tsv)

➜ echo $CLUSTER_SUBNET_ID
/subscriptions/56d9a591-8bfe-40fb-96a4-17b3ec30d23a/resourceGroups/MC_rg-aks-mooc-001_dwk-cluster_swedencentral/providers/Microsoft.Network/virtualNetworks/aks-vnet-14127093/subnets/aks-subnet
```

```bash
IDENTITY_RESOURCE_NAME='azure-alb-identity'

MC_RESOURCE_GROUP=$(az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP --query "nodeResourceGroup" -otsv | tr -d '\r')

mcResourceGroupId=$(az group show --name $MC_RESOURCE_GROUP --query id -otsv)
principalId=$(az identity show -g $RESOURCE_GROUP -n $IDENTITY_RESOURCE_NAME --query principalId -otsv)

# Delegate AppGw for Containers Configuration Manager role to AKS Managed Cluster RG
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --scope $mcResourceGroupId --role "fbc52c3f-28ad-4303-a892-8a056630b8f1"

# Delegate Network Contributor permission for join to association subnet
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --scope $ALB_SUBNET_ID --role "4d97b98b-1d4f-4787-a291-c67834d212e7"
```

I need a Network for my ALB controller:

```bash
export AKS_NAME='dwk-cluster' && \
export RESOURCE_GROUP='rg-aks-mooc-001' && \
MC_RESOURCE_GROUP=$(az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP --query "nodeResourceGroup" -o tsv) && \
CLUSTER_SUBNET_ID=$(az vmss list --resource-group $MC_RESOURCE_GROUP --query '[0].virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id' -o tsv) && \
VNET_NAME=$(az network vnet show --ids $CLUSTER_SUBNET_ID --query 'name' -o tsv) && \
VNET_RESOURCE_GROUP=$(az network vnet show --ids $CLUSTER_SUBNET_ID --query 'resourceGroup' -o tsv) && \
az network vnet subnet create \
  --resource-group $VNET_RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name alb-subnet \
  --address-prefixes 10.225.0.0/24 \
  --delegations 'Microsoft.ServiceNetworking/trafficControllers'
```

Then give the identity access to the resources:

```bash
export AKS_NAME='dwk-cluster' && \
export RESOURCE_GROUP='rg-aks-mooc-001' && \
export IDENTITY_RESOURCE_NAME='azure-alb-identity' && \
MC_RESOURCE_GROUP=$(az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP --query "nodeResourceGroup" -o tsv) && \
CLUSTER_SUBNET_ID=$(az vmss list --resource-group $MC_RESOURCE_GROUP --query '[0].virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id' -o tsv) && \
VNET_RESOURCE_GROUP=$(az network vnet show --ids $CLUSTER_SUBNET_ID --query 'resourceGroup' -o tsv) && \
VNET_NAME=$(az network vnet show --ids $CLUSTER_SUBNET_ID --query 'name' -o tsv) && \
ALB_SUBNET_ID=$(az network vnet subnet show --name alb-subnet --resource-group $VNET_RESOURCE_GROUP --vnet-name $VNET_NAME --query '[id]' -o tsv) && \
echo "ALB_SUBNET_ID: $ALB_SUBNET_ID"
```

```bash
export AKS_NAME='dwk-cluster' && \
export RESOURCE_GROUP='rg-aks-mooc-001' && \
export IDENTITY_RESOURCE_NAME='azure-alb-identity' && \
MC_RESOURCE_GROUP=$(az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP --query "nodeResourceGroup" -o tsv) && \
mcResourceGroupId=$(az group show --name $MC_RESOURCE_GROUP --query id -otsv) && \
principalId=$(az identity show -g $RESOURCE_GROUP -n $IDENTITY_RESOURCE_NAME --query principalId -otsv) && \
echo "Assigning AppGw for Containers Configuration Manager role..." && \
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --scope $mcResourceGroupId --role "fbc52c3f-28ad-4303-a892-8a056630b8f1"
```
