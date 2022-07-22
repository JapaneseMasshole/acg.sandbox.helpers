rg=$(az group list --query [].name -o tsv)
loc=$(az group list --query [].location -o tsv)
echo "resource group name is $rg"
echo "default location is $loc"
vnet=$(az network vnet list --query [].name -o tsv)

echo "Deleting virtual network $vnet and its subnets..."
az resource delete -g $rg -n $vnet --resource-type "Microsoft.Network/virtualNetworks"

pubip=$(az network public-ip list --query [].name -o tsv)
echo "Deleting public ip $pubip..."
az resource delete -g $rg -n $pubip --resource-type "Microsoft.Network/publicIPAddresses"

nsg=$(az network nsg list --query [].name -o tsv)
echo "Deleting network security group $nsg..."
az resource delete -g $rg -n $nsg --resource-type "Microsoft.Network/networkSecurityGroups"

echo "Entire deletion completed"