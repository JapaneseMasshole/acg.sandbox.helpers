<<<<<<< HEAD
$rg=Get-AzResourceGroup

$nsg = Get-AzNetworkSecurityGroup
Remove-AzNetworkSecurityGroup -Name $nsg.Name -ResourceGroupName $rg.ResourceGroupName -Force