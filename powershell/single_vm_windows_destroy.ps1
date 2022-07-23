$rg=Get-AzResourceGroup

$vm = Get-AzVM -ResourceGroupName $rg.ResourceGroupName
echo "Deleting virtual machine '$($vm.Name)'"
Remove-AzVM -ResourceGroupName $rg.ResourceGroupName -Name $vm.Name -Force


echo "Disassociate public ip address from NIC..."
$nic = Get-AzNetworkInterface -ResourceGroupName $rg.ResourceGroupName
$nic.IpConfigurations.publicipaddress.id = $null
Set-AzNetworkInterface -NetworkInterface $nic
echo "Deleting network interface '$($nic.Name)'"
Remove-AzNetworkInterface -ResourceGroupName $rg.ResourceGroupName -Name $nic.Name -Force

$pubip = Get-AzPublicIpAddress -ResourceGroupName $rg.ResourceGroupName
echo "Deleting public ip address '$($pubip.Name)'"
Remove-AzPublicIpAddress -Name $pubip.Name -ResourceGroupName $rg.ResourceGroupName -Force

$vnet = Get-AzVirtualNetwork -ResourceGroupName $rg.ResourceGroupName
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rg.ResourceGroupName

echo "Disassociate subnet from NSG..."
Set-AzVirtualNetworkSubnetConfig -Name $vnet.subnets[0].Name -VirtualNetwork $vnet -AddressPrefix $vnet.subnets[0].AddressPrefix -NetworkSecurityGroupId $null
$vnet | Set-AzVirtualNetwork

echo "Deleting network security group '$($nsg.Name)'"
Remove-AzNetworkSecurityGroup -Name $nsg.Name -ResourceGroupName $rg.ResourceGroupName -Force

echo "Deleting virtual network '$($vnet.Name)'"
Remove-AzVirtualNetwork -Name $vnet.Name -ResourceGroupName $rg.ResourceGroupName -Force




