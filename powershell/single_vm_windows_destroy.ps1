$rg=Get-AzResourceGroup

$vm = Get-AzVM -ResourceGroupName $rg.ResourceGroupName
echo "Deleting virtual machine '$($vm.Name)'"
Remove-AzVM -ResourceGroupName $rg.ResourceGroupName -Name $vm.Name -Force

$vnet = Get-AzVirtualNetwork -ResourceGroupName $rg.ResourceGroupName
echo "Deleting virtual network '$($vnet.Name)'"
Remove-AzVirtualNetwork -Name $vnet.Name -ResourceGroupName $rg.ResourceGroupName -Force

$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rg.ResourceGroupName
echo "Deleting network security group '$($nsg.Name)'"
Remove-AzNetworkSecurityGroup -Name $nsg.Name -ResourceGroupName $rg.ResourceGroupName -Force

$pubip = Get-AzPublicIpAddress -ResourceGroupName $rg.ResourceGroupName
echo "Deleting public ip address '$($pubip.Name)'"
Remove-AzPublicIpAddress -Name $pubip.Name -ResourceGroupName $rg.ResourceGroupName -Force