$rg=Get-AzResourceGroup
$nsgname="nsg1"
$nicname="nic1"
$vnetname="vnet1"
$subnetname="default"
$pubipname="pip-win-vm1"
$vmname="vm01"
$imagename="Win2019Datacenter"
$sizename="Standard_B1s"

echo "resource group name is " $rg.ResourceGroupName
echo "default location is " $rg.Location

#Creating resources

echo "Creating Network Security Group '$nsgname'"
$nsg = New-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $rg.ResourceGroupName  -Location  $rg.Location

echo "Creating Public IP Address '$pubipname'"
$pubipparams = @{
    Name = $pubipname
    Location = $rg.Location
    ResourceGroupName = $rg.ResourceGroupName
    AllocationMethod = "Static"
}

$pubip = New-AzPublicIPAddress @pubipparams

echo "Creating Virtual Network '$vnetname'"
$vnet = @{
    Name = $vnetname
    ResourceGroupName = $rg.ResourceGroupName
    Location = $rg.Location
    AddressPrefix = '10.0.0.0/16'    
}
$virtualNetwork = New-AzVirtualNetwork @vnet

echo "Configuration subnet"
$subnet = @{
    Name = $subnetname
    VirtualNetwork = $virtualNetwork
    AddressPrefix = '10.0.0.0/24'
    NetworkSecurityGroup = $nsg
}
$subnetConfig = Add-AzVirtualNetworkSubnetConfig @subnet

echo "Updating virtual network with newly added subnet"
$virtualNetwork | Set-AzVirtualNetwork

echo "Creating a new virtual machine..."
<#
$vm1 = @{
    ResourceGroupName = $rg.ResourceGroupName
    Location = $rg.Location
    Name = $vmname
    VirtualNetworkName = $virtualNetwork.Name
    SubnetName = $subnet.Name
    DataDiskDeleteOption = 'Delete'
    NetworkInterfaceDeleteOption = 'Delete'
    Image = "Win2019Datacenter"
    Size = "Standard_B1s"
    OSDiskDeleteOption = "Delete"

}
New-AzVM @vm1 -AsJob
#>



<#
$UserName = "azureuser"
$Password = ConvertTo-SecureString "P@ssword123" -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($UserName, $Password)
#>

$Vnet = (Get-AzVirtualNetwork -ResourceGroup $rg.ResourceGroupName)
$NIC = New-AzNetworkInterface -Name $nicname -ResourceGroupName $rg.ResourceGroupName -Location $virtualNetwork.Location -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $pubip.Id
$VirtualMachine = New-AzVMConfig -VMName $vmname -VMSize $sizename
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $vmname -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2022-datacenter-azure-edition-core' -Version latest
New-AzVm -ResourceGroupName $rg.ResourceGroupName -Location $virtualNetwork.Location -VM $VirtualMachine
echo "Deployment completed."