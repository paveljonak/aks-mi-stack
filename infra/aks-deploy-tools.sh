#!/bin/bash
source ./common/scripts/init-env-variables.sh
if [ $? -ne 0 ]; then 
    echo "Error while reading sources of module" 
    exit 1;
fi

# LOG "All deployment operations finished."
# echo "Preparing kube config...."
az account set --subscription ${AZURE_SUBSCRIPTION_ID}
az aks get-credentials -n ${RESOURCE_BASE_NAME} -g ${AZURE_RESOURCE_GROUP} --admin --overwrite-existing

#sleep 20


# # # Only for dev purposes
# LOG "Deployment of all apps into cluster started."
# cd ../../deployment
# ./aks-deploy-apps.sh
# LOG "AKS deployment of tools ended."