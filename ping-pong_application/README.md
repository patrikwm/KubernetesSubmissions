# Chapter 4

# Exercise: 3.3. To the Gateway

- To use gateway with AKS you need to use Azure Application Gateway for Containers (ALB).
- ALB is more complex to set up but has more features and better integration with Azure.
- [Application gateway for containers](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller?tabs=install-helm-windows)
- It requires the cluster and ALB to be in a supprted region.
- It requires specific network setup.
- The ALB controller needs to be installed in the cluster.
- The Managed Identity needs to be created and assigned permissions.
- The Kubernetes Cluster needs to have OIDC issuer enabled.


## Network setup

Since the network setup is complex, i will use the provided scripts to create the network and cluster.

