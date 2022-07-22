#Setting local variables
rg=$(az group list --query [].name -o tsv)
loc=$(az group list --query [].location -o tsv)
nsg="nsg1"
nic="nic1"
vnetname="vnet1"
subnetname="subnet1"
pubip="pip-win-vm1"

echo "resource group name is $rg"
echo "default location is $loc"

#Creating resources

echo "Creating Network Security Group '$nsg'..."
az network nsg create -g $rg -l $loc -n $nsg

echo "Creating public ip '$pubip'..."
az network public-ip create -g $rg -l $loc -n $pubip

echo "Creating virtual network '$vnetname' & subnet '$subnetname'..."
az network vnet create -g $rg -l $loc -n $vnetname --subnet-name $subnetname --nsg $nsg

echo "Creating nic '$nic'..."
az network nic create  -g $rg -l $loc -n $nic --public-ip-address $pubip --subnet $subnetname


