# Kubernetes Lab

A personal DevOps lab project focused on building and running a scalable, cloud-native application infrastructure on Azure.

The architecture consists of:
- **Infrastructure:** Provisioned and managed using Terraform, split into modules, with remote state in Azure Storage.
- **Orchestration:** AKS cluster with Azure CNI Overlay networking.
- **Backend:** .NET 10 Web API, packaged as a Helm chart and running as a non-root container.
- **Routing:** Kubernetes Gateway API through the AKS application routing add-on.
- **GitOps:** ArgoCD deploys everything inside the cluster from this repository.
- **Auto-scaling:** Horizontal Pod Autoscaler on the API (1 to 4 replicas).
- **Monitoring:** Prometheus and Grafana for metrics, monitoring, and visualization.
- **Registry:** Azure Container Registry, pulled with the cluster's managed identity.
- **Database:** Azure SQL Database (MSSQL) with Entra-only authentication.
- **Secrets:** Azure Key Vault.

## Current Status

The foundational infrastructure is in place:
- [x] Terraform infrastructure
- [x] Kubernetes cluster
- [x] Azure SQL Database and Key Vault
- [x] .NET API deployment with Helm
- [x] Gateway API routing
- [x] Auto-scaling configuration
- [x] ArgoCD integration
- [x] Prometheus & Grafana monitoring
- [x] Non-root container with a hardened security context
- [ ] Cluster attached to the Terraform-managed virtual network
- [ ] Workload Identity, so the API can use Azure SQL and Key Vault without secrets
- [ ] Network policies
- [ ] HTTPS on the gateway
- [ ] CI pipeline with GitHub Actions
- [ ] Angular frontend deployment

## Running It

Requires Azure CLI, Terraform, kubectl and Docker, plus an existing storage account for the Terraform state (configured in `environments/dev/providers.tf`).

```bash
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TF_VAR_sql_admin_login="<put your signin name here>"

cd environments/dev
terraform init
terraform apply

az acr login --name bhazureakslabacr
docker build -t bhazureakslabacr.azurecr.io/labapi:1.2 ../../api
docker push bhazureakslabacr.azurecr.io/labapi:1.2

az aks get-credentials --resource-group rg-compute-main --name main-cluster
kubectl apply -f ../../argocd/bootstrap/root.yaml
```

From there ArgoCD takes over and syncs the API, the gateway and the monitoring stack from this repository.

This lab is an ongoing project to explore Kubernetes, Infrastructure as Code, GitOps, cloud-native application deployment, and observability in an Azure environment.
