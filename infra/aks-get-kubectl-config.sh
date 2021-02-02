#!/bin/bash
source ./common/scripts/init-env-variables.sh
if [ $? -ne 0 ]; then 
    echo "Error while reading sources of module" 
    exit 1;
fi

az account set --subscription ${AZURE_SUBSCRIPTION_ID}
az aks get-credentials -n ${RESOURCE_BASE_NAME} -g ${AZURE_RESOURCE_GROUP} --admin --overwrite-existing