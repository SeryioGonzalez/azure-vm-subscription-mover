#!/bin/bash

source config.sh

az account set --subscription $oldSubs

for RG_DATA in $(az group list --query "[].{name:name, location:location}" -o tsv | sed -e 's/\t/,/g')
do
	rgName=$(echo $RG_DATA     | cut -d, -f1)
	rgLocation=$(echo $RG_DATA | cut -d, -f2)
	
	az group create --subscription $newSubs -l $rgLocation -n $rgName
done
