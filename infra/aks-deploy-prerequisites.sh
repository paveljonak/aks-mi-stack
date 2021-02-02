#!/bin/bash
source ./common/scripts/init-env-variables.sh
if [ $? -ne 0 ]; then
    echo "Error while reading sources of module"
    exit 1;
fi

LOG "Set azure account with subscription id ${AZURE_SUBSCRIPTION_ID}"
az account set --subscription ${AZURE_SUBSCRIPTION_ID}
LOG_EXIT "Error while selecting azure subscription"

[ -z "${RESOURCE_BASE_NAME}" ] && LOG "RESOURCE_BASE_NAME variable empty or undefined" &&  exit 1;

LOG "Checking of admin group for AKS"
az ad group list -o tsv | grep ${AKS_ADMIN_GROUP} -q || az ad group create \
    --display-name ${AKS_ADMIN_GROUP} --mail-nickname ${AKS_ADMIN_GROUP}
LOG_EXIT "Error while processing deployment"

LOG "Checking of SSH keys for nodes"
if [ ! -f "${SSH_RSA_KEY_FILE}" ]; then
    ssh-keygen \
        -m PEM \
        -t rsa \
        -b 4096 \
        -C "${SSH_USER}" \
        -f "${SSH_RSA_KEY_FILE}" \
        -N "${SSH_PASS_PHRASE}"
    if [ $? -ne 0 ]; then
        echo "Generating of SSH keys interupted."
        exit 1;
    fi
fi


# LOG "Checking of keyvault for AKS"
# az keyvault list -o tsv | grep ${AKS_KEYVAULT_NAME} -q || az keyvault create \
#     --name ${AKS_KEYVAULT_NAME} \
#     --location ${AZURE_LOCATION} \
#     --subscription ${AZURE_SUBSCRIPTION_ID} \
#     --sku "Standard_B1"


LOG "Checking of resource group of AKS"
az group list -o tsv | grep ${AZURE_RESOURCE_GROUP} -q || az group create \
    --name ${AZURE_RESOURCE_GROUP} \
    --location ${AZURE_LOCATION} \
    --subscription ${AZURE_SUBSCRIPTION_ID} \
    --verbose
LOG_EXIT "Error while processing deployment"

LOG "Checking of vNet"
az network vnet list -o tsv -g ${AZURE_RESOURCE_GROUP} | grep ${VNET_NAME} -q || \
    az network vnet create \
        --resource-group ${AZURE_RESOURCE_GROUP} \
        --name ${VNET_NAME} \
        --address-prefixes ${VNET_ADDRESS_PREFIX} \
        --subnet-name ${SUBNET_NAME} \
        --subnet-prefix ${SUBNET_ADDRESS_PREFIX}
LOG_EXIT "Error while processing deployment"

LOG "Checking of resource group of IP addresses"
az group list -o tsv | grep ${AZURE_RESOURCE_GROUP_PIP} -q || az group create \
    --name ${AZURE_RESOURCE_GROUP_PIP} \
    --location ${AZURE_LOCATION} \
    --subscription ${AZURE_SUBSCRIPTION_ID} \
    --verbose
LOG_EXIT "Error while processing deployment"

LOG "Checking of Ingress Public IP Address"
az network public-ip list -o tsv -g ${AZURE_RESOURCE_GROUP_PIP} | grep ${NET_INGRESS_PUBLIC_IP} -q || \
    az network public-ip create \
        --resource-group ${AZURE_RESOURCE_GROUP_PIP} \
        --name ${NET_INGRESS_PUBLIC_IP} \
        --location ${AZURE_LOCATION} \
        --subscription ${AZURE_SUBSCRIPTION_ID} \
        --sku Standard
LOG_EXIT "Error while processing deployment"

LOG "Checking of resource group of Log Analytics Workspace"
az group list -o tsv | grep ${AZURE_RESOURCE_GROUP_LAW} -q || az group create \
    --name ${AZURE_RESOURCE_GROUP_LAW} \
    --location ${AZURE_LOCATION} \
    --subscription ${AZURE_SUBSCRIPTION_ID} \
    --verbose
LOG_EXIT "Error while processing deployment"

LOG "Checking of Log Analytics Workspace"
az monitor log-analytics workspace list -o tsv -g ${AZURE_RESOURCE_GROUP_LAW} | grep ${LOG_ANALYTICS_WORKSPACE_NAME} -q || \
    az monitor log-analytics workspace create \
        --resource-group ${AZURE_RESOURCE_GROUP_LAW} \
        --workspace-name ${LOG_ANALYTICS_WORKSPACE_NAME} \
        --location ${AZURE_LOCATION} \
        --subscription ${AZURE_SUBSCRIPTION_ID}
LOG_EXIT "Error while processing deployment"

LOG "Deploy of AKS prerequisites successfully done."