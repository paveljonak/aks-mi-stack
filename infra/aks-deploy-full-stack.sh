#!/bin/bash

./infra/aks-deploy-prerequisites.sh $1
./infra/aks-deploy-arm.sh $1
./infra/aks-deploy-role-assignment.sh $1