$rg=Get-AzResourceGroup
$nsgname="nsg1"
$nic="nic1"
$vnetname="vnet1"
$subnetname="subnet1"
$pubip="pip-win-vm1"
$vmname="vm01"
$imagename="Win2019Datacenter"
$sizename="Standard_B1s"

echo "resource group name is " $rg.ResourceGroupName
echo "default location is " $rg.Location

#Creating resources

echo "Creating Network Security Group " $nsg
$nsg = New-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $rg.ResourceGroupName  -Location  $rg.Location
