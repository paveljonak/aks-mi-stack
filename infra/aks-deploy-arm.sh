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

LOG "Checking resource group"
$(az group list --output tsv | grep ${AZURE_RESOURCE_GROUP} -q)
LOG_EXIT "Resource group ${AZURE_RESOURCE_GROUP} does not exist. "

SUBNET_ID=$(az network vnet subnet show --resource-group ${AZURE_RESOURCE_GROUP} --vnet-name ${VNET_NAME} --name ${SUBNET_NAME} --query id -o tsv)
[ -z "${SUBNET_ID}" ] && LOG "Error while processing deployment - SUBNET_ID variable empty or undefined" && exit 1;

ADMIN_GROUP_ID=$(az ad group show --group ${AKS_ADMIN_GROUP} --query objectId -o tsv)
[ -z "${ADMIN_GROUP_ID}" ] && LOG "Error while processing deployment - ADMIN_GROUP_ID variable empty or undefined" && exit 1;

SSH_RSA_PUBLIC_KEY=$(cat ./${SSH_RSA_KEY_FILE}.pub)
[ -z "${SSH_RSA_PUBLIC_KEY}" ] && LOG "Error while processing deployment - SSH_RSA_PUBLIC_KEY variable empty or undefined" && exit 1;

LOG "AKS deployment validation"
az deployment group validate \
--resource-group ${AZURE_RESOURCE_GROUP} \
--template-file ${AZURE_TEMPLATE_FILENAME} \
--parameters @${AZURE_PARAMETERS_FILENAME} \
                aksName=${AKS_NAME} \
                projectName=${PROJECT_NAME} \
                slotName=${SLOT_NAME} \
                nameDelimiter=${NAME_DELIMITER} \
                environment=${ENVIRONMENT} \
                linuxAdminUsername=${SSH_USER} \
                sshRSAPublicKey="${SSH_RSA_PUBLIC_KEY}" \
                adminGroupObjectIDs=${ADMIN_GROUP_ID} \
--subscription ${AZURE_SUBSCRIPTION_ID} \
--mode Incremental #\
#--verbose

LOG_EXIT "Error while validating AKS template"

az deployment group create \
--name "aks-deployment" \
--resource-group ${AZURE_RESOURCE_GROUP} \
--template-file ${AZURE_TEMPLATE_FILENAME} \
--parameters @${AZURE_PARAMETERS_FILENAME} \
                aksName=${AKS_NAME} \
                projectName=${PROJECT_NAME} \
                slotName=${SLOT_NAME} \
                nameDelimiter=${NAME_DELIMITER} \
                environment=${ENVIRONMENT} \
                linuxAdminUsername=${SSH_USER} \
                sshRSAPublicKey="${SSH_RSA_PUBLIC_KEY}" \
                adminGroupObjectIDs=${ADMIN_GROUP_ID} \
--subscription ${AZURE_SUBSCRIPTION_ID} \
--mode Incremental #\
#--verbose

LOG_EXIT "Error while deploying AKS ARM template"
LOG "Deploy of AKS ARM template successfully done."