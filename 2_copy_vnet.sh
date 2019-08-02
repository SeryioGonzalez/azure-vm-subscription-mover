#!/bin/bash

source config.sh

az account set --subscription $oldSubs



for VNET_DATA in $(az network vnet list --query "[].{name:name, addressSpace:addressSpace.addressPrefixes[0], resourceGroup:resourceGroup, location:location, subnetName:subnets[0].name, subnetPrefix:subnets[0].addressPrefix}" -o tsv | sed -e 's/\t/,/g')
do

	vnetName=$(echo $VNET_DATA     | cut -d, -f1)
	vnetPref=$(echo $VNET_DATA     | cut -d, -f2)
	vnetRG=$(echo $VNET_DATA       | cut -d, -f3)
	vnetLocation=$(echo $VNET_DATA | cut -d, -f4)
	subnetName=$(echo $VNET_DATA   | cut -d, -f5)
	subnetPref=$(echo $VNET_DATA   | cut -d, -f6)
	
	#IT JUST CREATES A SINGLE SUBNET PER VNET. ADDITIONAL VNETS ARE NOT IN SCOPE
	echo "az network vnet create -l $vnetLocation -n $vnetName -g $vnetRG --address-prefixes $vnetPref --subnet-name $subnetName --subnet-prefixes $subnetPref --subscription $newSubs"
done
