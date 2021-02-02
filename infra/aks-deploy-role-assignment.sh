#!/bin/bash
source ./common/scripts/init-env-variables.sh
if [ $? -ne 0 ]; then 
    echo "Error while reading sources of module" 
    exit 1;
fi

LOG "Set azure account to subscription ${AZURE_SUBSCRIPTION_ID}"
az account set --subscription ${AZURE_SUBSCRIPTION_ID}
LOG_EXIT "Error while selecting azure subscription"

aksManagedServicePrincipalID=$(az aks show -g ${AZURE_RESOURCE_GROUP} -n ${RESOURCE_BASE_NAME} --query "identity.principalId" -o tsv)
kubeletIdentityObjectId=$(az aks show -g ${AZURE_RESOURCE_GROUP} -n ${RESOURCE_BASE_NAME} --query identityProfile.kubeletidentity.objectId --out tsv)
LOG "Managed Identity Principal ID: ${aksManagedServicePrincipalID}"
LOG "Managed Identity Kubelet Principal ID: ${kubeletIdentityObjectId}"
[ -z "${aksManagedServicePrincipalID}" ] && LOG "Error while processing deployment - aksManagedServicePrincipalID variable empty or undefined" && exit 1;
[ -z "${kubeletIdentityObjectId}" ] && LOG "Error while processing deployment - kubeletIdentityObjectId variable empty or undefined" && exit 1;

VNET_ID=$(az network vnet show --resource-group ${AZURE_RESOURCE_GROUP} --name ${VNET_NAME} --query id -o tsv)
[ -z "$VNET_ID" ] && LOG "Error while processing deployment - VNET_ID variable empty or undefined" && exit 1;
SUBNET_ID=$(az network vnet subnet show --resource-group ${AZURE_RESOURCE_GROUP} --vnet-name ${VNET_NAME} --name ${SUBNET_NAME} --query id -o tsv)
[ -z "$SUBNET_ID" ] && LOG "Error while processing deployment - SUBNET_ID variable empty or undefined" && exit 1;

LOG "Assign role Network Contributor for AKS MI Principal ID into scope ${VNET_ID}"
az role assignment create \
    --assignee ${aksManagedServicePrincipalID} \
    --role  "Network Contributor" \
    --scope ${VNET_ID}
LOG_EXIT "Error while processing deployment"

LOG "Assign role Network Contributor for AKS MI Principal ID into scope ${SUBNET_ID}"
az role assignment create \
    --assignee ${aksManagedServicePrincipalID} \
    --role  "Network Contributor" \
    --scope ${SUBNET_ID}
LOG_EXIT "Error while processing deployment"

LOG "Assign role Network Contributor for AKS MI Principal ID into scope ${AZURE_RESOURCE_GROUP_PIP}"
az role assignment create \
    --assignee ${aksManagedServicePrincipalID} \
    --role  "Network Contributor" \
    --resource-group ${AZURE_RESOURCE_GROUP_PIP}
LOG_EXIT "Error while processing deployment"


acrId=$(az acr show -n ${ACR_NAME} --query id -o tsv)
LOG_EXIT "Error while processing deployment"
[ -z "${acrId}" ] && LOG "Error while processing deployment - acrId variable empty or undefined" && exit 1;
if [ "${acrId}" ]; then
    LOG "Assign role AcrPull to scope MI kubelet principal ID to scope container registry ${ACR_NAME}.azurecr.io"
    az role assignment create \
        --assignee ${kubeletIdentityObjectId} \
        --role acrpull \
        --scope ${acrId}
    LOG_EXIT "Error while processing deployment"
fi

aksId=$(az aks show -n ${RESOURCE_BASE_NAME} -g ${AZURE_RESOURCE_GROUP} --query id -o tsv)
[ -z "${aksId}" ] && LOG "Error while processing deployment - aksId variable empty or undefined" && exit 1;
logAnalyticsWorkspaceId=$(az monitor log-analytics workspace show --workspace-name ${LOG_ANALYTICS_WORKSPACE_NAME} -g ${AZURE_RESOURCE_GROUP_LAW} --query id -o tsv)
[ -z "${logAnalyticsWorkspaceId}" ] && LOG "Error while processing deployment - acrId variable empty or undefined" && exit 1;
if [ "$logAnalyticsWorkspaceId" ]; then
    LOG "Assign role for log analytics workspace integration."
    az role assignment create \
        --assignee ${aksManagedServicePrincipalID} \
        --role '3913510d-42f4-4e42-8a64-420c390055eb' \
        --scope ${logAnalyticsWorkspaceId}
    LOG_EXIT "Error while processing deployment"
fi

LOG "Deploy of Role Assignment successfully done."