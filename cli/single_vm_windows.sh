rg=$(az group list --query [].name -o tsv)
loc=$(az group list --query [].location -o tsv)
echo "resource group name is $rg"
echo "default location is $loc"