#!/bin/bash

source config.sh

az account set --subscription $oldSubs

for VM_DATA in $(az vm list -o tsv --query "[].{
						name         : name,
						vmOsType     : storageProfile.osDisk.osType, 
						vmOsDiskId   : storageProfile.osDisk.managedDisk.id,
						vmDataDiskId : storageProfile.dataDisks[0].managedDisk.id,
						vmNicId      : networkProfile.networkInterfaces[0].id,
						vmLocation   : location,
						vmResGroup   : resourceGroup,
						vmSize       : hardwareProfile.vmSize,
						vmId         : id
						 
					}" | sed -e 's/\t/,/g')
do
	vmName=$(echo $VM_DATA       | cut -d, -f1)
	vmOsType=$(echo $VM_DATA     | cut -d, -f2)
	vmOsDiskId=$(echo $VM_DATA   | cut -d, -f3)
	vmDataDiskId=$(echo $VM_DATA | cut -d, -f4)
	vmNicId=$(echo $VM_DATA      | cut -d, -f5)
	vmLocation=$(echo $VM_DATA   | cut -d, -f6)
	vmResGroup=$(echo $VM_DATA   | cut -d, -f7)
	vmSize=$(echo $VM_DATA       | cut -d, -f8)
	vmId=$(echo $VM_DATA         | cut -d, -f9)	
	
	vmPrivateIp=$(az network nic show --ids $vmNicId -o tsv --query "ipConfigurations[].privateIpAddress")
	vmSubnetId=$(az network nic show --ids $vmNicId -o tsv --query "ipConfigurations[].subnet.id" | sed "s/$oldSubs/$newSubs/")
	
	vmOsDiskName=$(echo $vmOsDiskId | cut -d"/" -f 9)

	echo "#COMMANDS FOR MIGRATING $vmName"
	
	echo "	#STOP VM"	
	echo "az vm stop --ids $vmId"
	echo "	#CREATE OS DISK"	
	echo "az disk create -g $vmResGroup -n $vmOsDiskName --source $vmOsDiskId --subscription $newSubs"

	echo "vmOsDiskId=\$(az disk show -g $vmResGroup -n $vmOsDiskName --query 'id' -o tsv --subscription $newSubs)"
	
	vmCreateCommand="az vm create -n $vmName -g $vmResGroup --attach-os-disk \$vmOsDiskId --os-type $vmOsType --subnet $vmSubnetId --private-ip-address $vmPrivateIp --subscription $newSubs"
	
	if [ $vmDataDiskId != "None" ]
	then
		vmDataDiskName=$(echo $vmDataDiskId | cut -d"/" -f 9)
		echo " #CREATE DATA DISK"
		echo "az disk create -g $vmResGroup --name $vmDataDiskName --source $vmDataDiskId --subscription $newSubs"
		echo "vmDataDiskId=\$(az disk show -g $vmResGroup -n $vmDataDiskName --query 'id' -o tsv --subscription $newSubs)"
		
		vmCreateCommand="$vmCreateCommand --attach-data-disks \$vmDataDiskId"
	fi
	
	echo " #CREATE VM"
	echo $vmCreateCommand
	
	echo ""
	echo ""
	
done
