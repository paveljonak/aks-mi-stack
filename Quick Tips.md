# Deploy AKS via arm template and shell

### How to retrieve some of basic parameters e.g. for prerequisites
List all available AKS versions
```
source .env-dev-blue
az aks get-versions --location ${AZURE_LOCATION} -o table
```

### Set variable with ssh key
Set SSH key
```
# Export any key you want
export SSH_RSA_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)
```


### Query managed aks identity
```
# Show managed identity data
az aks show -g myResourceGroup -n myManagedCluster --query "identity"

# Read principal ID from AKS managed identity
aksManagedServicePrincipalID=$(az aks show -g myResourceGroup -n myManagedCluster --query "identity.principalId" -o tsv)

```
### Delete whole AKS environment
```
source .env
az deployment group delete --name "aks-deployment" --resource-group ${AZURE_RESOURCE_GROUP}
```