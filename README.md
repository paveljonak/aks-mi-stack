# AKS with MI (Managed Identity) Deployment Guideline

## Why Managed Identity AKS

<p>
Currently, an Azure Kubernetes Service (AKS) cluster (specifically, the Kubernetes cloud provider) requires an identity to create additional resources like load balancers and managed disks in Azure. This identity can be either a managed identity or a service principal. If you use a service principal, you must either provide one or AKS creates one on your behalf. If you use managed identity, this will be created for you by AKS automatically. Clusters using service principals eventually reach a state in which the service principal must be renewed to keep the cluster working. Managing service principals adds complexity, which is why it's easier to use managed identities instead. The same permission requirements apply for both service principals and managed identities.
</br>

Managed identities are essentially a wrapper around service principals, and make their management simpler. Credential rotation for MI happens automatically every 46 days according to Azure Active Directory default. AKS uses both system-assigned and user-assigned managed identity types. These identities are currently immutable. To learn more, read about managed identities for Azure resources.
</p>

- https://docs.microsoft.com/cs-cz/azure/aks/use-managed-identity

## Module description

### Scope

The focus is on deploy pipeline of AKS using Managed Identites
- Local execution of pipeline
- Cloud execution of pipeline (e.g. Azure Pipelines, Gitlab)

### How to use this module
- Base working directory path for correct execution of scripts is in root (aks-stack folder)
- Each deployment script needs to be run with path to configuration file (e.g.  .env-blue-dev file).
- Each deployment script uses same configuration file for same setup.

```
# Run this to deploy prerequisites for AKS
# This step tries to check and create all missing resources related to AKS.
./infra/aks-deploy-prerequisites.sh .env-dev-blue

# Run this to deploy ARM AKS template
# This step tries to deploy ARM template as AKS resource deployment.
./infra/aks-deploy-arm.sh .env-dev-blue

# Run this to deploy role assignment for resources managed by AKS
# This step tries to deploy and set all roles for all related resources
# It has to be executed after AKS is created - need to read MI profile and its principal IDs.
./infra/aks-deploy-role-assignment.sh .env-dev-blue

```

## Simply spin up AKS in regions
```

# AKS Dev in West Europe
./infra/aks-deploy-full-stack.sh .dev.we.blue

# AKS Test in West Europe
./infra/aks-deploy-full-stack.sh .test.we.blue

# AKS Sint in West Europe
./infra/aks-deploy-full-stack.sh .sint.we.blue

# AKS Prod in West Europe
./infra/aks-deploy-full-stack.sh .prod.we.blue

# AKS Prod in Australia East
./infra/aks-deploy-full-stack.sh .prod.ae.blue

# AKS Prod in Central India
./infra/aks-deploy-full-stack.sh .prod.ci.blue

```

### Naming convention for Azure resources in script and ARM template:
```
# Naming convention
     [ProjectName][Delimiter][Environemnt][Delimiter][AzureLocationShowrt][Delimiter][AKSResourceName][Delimiter][SlotName]
```
### Multiple level configuration


- .env-cfg-file - This file contains soft parameters for everyday basic operations, assuming that it can be modified frequently
- azuredeploy.parameters.json - In this file is possible to set parameters for advanced configuration e.g.
    - Fully adjustable Network Profile
    - System node pool (Mode=System) (e.g. size, scaling, subnet)
    - User node pool (Mode=User) (e.g. size, scaling, subnet)
- azuredeploy.json - Lot of predefined parameters with overriding option

NOTE: ARM template used in this module only allow creating new pools and customize them. With This ARM template is not possible to delete any node pool.

## Prerequisites

### Related resources
- AKS uses lot of resources linked to itself. This module is able to create the most of them, but of course it is possible to use already existing resources (Check compatibility before e.g. Load Balancer SKU )
- All related resources are in same subscription

#### Related resources and its creation not supported by this deployment module
- ACR
    - Always uses existing resource.
    - AKS is joined only with AcrPull role by MI kubelet identity ID.
#### Related resources and its creation supported by this deployment module
- vNet & AKS Subnet
    - Identified by Name and Resource group name. In case this resource does not exist module creates it. (Default Resource Group is same as group for AKS resource)
    - Check RBAC integration section for more info about roles for this resource.
- Public static IP
    - Identified by Name and Resource group name. In case this resource does not exist module creates it.
    - Check RBAC integration section for more info about roles for this resource.
    - Be sure that SKUs of IP and AKS LB is same
- Log Analytics Workspace
    - Identified by Name and Resource group name. In case this resource does not exist module creates it
    - Check RBAC integration section for more info about roles for this resource.


### Linux shell with working az cli connection into azure

az cli version with support zero base index in ARM templates

```
$ az version
```
### Check or Register Features

In case of exception with message containing any information about features bellow, just register them
```
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService')]"
az feature list -o table --query "[?contains(name, 'Microsoft.OperationsManagement')].

register Microsoft.OperationsManagement
register Microsoft.ContainerService
```


### AAD & Azure Subscription RBAC integration for deploy of AKS with MI using this module

- https://docs.microsoft.com/en-us/answers/questions/162264/built-in-roles-for-azure-kubernetes-service-aks.html
- https://medium.com/@weinong/azure-kubernetes-service-built-in-roles-8083b90e7ba


#### Preexisting AAD Group for cluster admins

For AKS AAD integration is used ID of group. To this Admin groups is possible to join other members in AKS admin role. This group is not created automatically during AKS deployment. ID of Group have to be filled up in configuration

#### Role types and different kind of role usage

- Roles in minimum needed variant are different in first spinning up AKS, or adjusting existing one later. This is aks deployment flow according to RBAC needs.

**Deploy AKS prerequisites on green field**

Let's say we just have nothing and what roles we need to achieve these individual steps with different role needs?
- Create Resource Group for AKS home
    - **Role**: Contributor on Subscription
- Create Resource Group for vNet
    - **Role**: Contributor on Subscription
        - Create vNet for AKS
            - **Role**: Network Contributor on Resource Group containing vNet for AKS
- Create Resource Group for public IP (if not exists, or dont want to use any other - Manageable via configuration)
    - **Role**: Contributor on Subscription
        - Create Public Static IP
            - **Role**: Network Contributor on Resource Group containing Public Static IP
- Create Resource Group for Log Analytics Workspace (if not exists, or dont want to use any other -Manageable via configuration)
    - **Role**: Contributor on Subscription
        - Create Log Analytics
            - Log Analytics Contributor


**Deploy AKS into already existing prerequisite resources**
Let's say we already have prerequisites resources

- Create AKS
    - **Role**: Azure Kubernetes Service Contributor Role on AKS Home resource group
    - **Role**: Log Analytics Contributor on observability resource group with Log Analytics Workspace


**Associate roles and grant permissions for them (After AKS deploy)**
Last step is to setup all necessary roles for AKS for managing resources by itself

- Create Role Assignments
    - **Role**: User Access Administrator / Owner on resource groups or individual resources


#### List of necessary rules

<table>
<tr>
    <th>Goal</th><th>Rule action</th><th>Minimum role on specific scope</th>
</tr>
<tr>
    <td>Create resource group for AKS</td> <td>Microsoft.Resources/subscriptions/resourcegroups/write<t/d> <td>Contributor - on Subscription level</td>
</tr>
<tr>
    <td>Create VNet for AKS</td> <td>Microsoft.Network/virtualNetworks/write</td> <td>Network Contributor - on AKS home esource group</td>
</tr>
<tr>
    <td>Create AKS</td> <td>Microsoft.ContainerService/managedClusters/write</td> <td>Azure Kubernetes Service Contributor Role - on AKS home esource group</td>
</tr>
<tr>
    <td></td> <td>Microsoft.OperationsManagement/solutions/write</td> <td>Log Analytics Contributor - on Log Analytics Workspace</td>
</tr>
<tr>
    <td>Create Role Assignment for resources managed by AKS (vNet,Subnet,ACR,Logs etc.)</td> <td>Microsoft.Authorization/roleAssignments/write</td> <td>User Access Administrator - on resource groups or individual resources wants to be managed by AKS </td>


</tr>
</table>



