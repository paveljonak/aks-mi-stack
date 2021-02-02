#!/bin/bash
source $1 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error while reading env variables file. Provide correct env variables file and run this script again."
    exit 1;
fi
source "./common/scripts/logger"
if [ $? -ne 0 ]; then
    echo "Error while reading logger module"
    exit 1;
fi

validationFailed=0
#[ -z "${NAME_DELIMITER}" ] && LOG "NAME_DELIMITER variable empty or undefined." && validationFailed=1;
[ -z "${TENANT_ID}" ] && LOG "TENANT_ID variable empty or undefined." && validationFailed=1;
[ -z "${AZURE_SUBSCRIPTION_ID}" ] && LOG "AZURE_SUBSCRIPTION_ID variable empty or undefined." && validationFailed=1;
[ -z "${ENVIRONMENT}" ] && LOG "ENVIRONMENT variable empty or undefined." && validationFailed=1;
[ -z "${AKS_NAME}" ] && LOG "AKS_NAME variable empty or undefined." && validationFailed=1;
[ -z "${SLOT_NAME}" ] && LOG "SLOT_NAME variable empty or undefined." && validationFailed=1;

if [ $validationFailed -ne 0 ]; then
    LOG "Init and Validation of Environment variables failed."
    exit 1;
fi

RESOURCE_BASE_NAME="${PROJECT_NAME}${NAME_DELIMITER}${ENVIRONMENT}${NAME_DELIMITER}${AZURE_LOCATION_SHORT}${NAME_DELIMITER}${AKS_NAME}${NAME_DELIMITER}${SLOT_NAME}"
AZURE_RESOURCE_GROUP="${RESOURCE_BASE_NAME}${NAME_DELIMITER}rg"
AZURE_RESOURCE_GROUP_PIP="${RESOURCE_BASE_NAME}${NAME_DELIMITER}ip${NAME_DELIMITER}rg"
AZURE_RESOURCE_GROUP_LAW="${RESOURCE_BASE_NAME}${NAME_DELIMITER}law${NAME_DELIMITER}rg"

VNET_NAME="${RESOURCE_BASE_NAME}${NAME_DELIMITER}vnet"
SUBNET_NAME="${RESOURCE_BASE_NAME}${NAME_DELIMITER}subnet"
NET_INGRESS_PUBLIC_IP="${RESOURCE_BASE_NAME}${NAME_DELIMITER}ip"
LOG_ANALYTICS_WORKSPACE_NAME="${RESOURCE_BASE_NAME}${NAME_DELIMITER}law"
AKS_KEYVAULT_NAME="${RESOURCE_BASE_NAME}${NAME_DELIMITER}kv"

LOG "Init and Validation of Environment variables successfully done."