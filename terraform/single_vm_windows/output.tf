output "storage_account_name" {
    value = data.azurerm_storage_account.storageacct.name
}

output "new_vnet_name" {
    value = azurerm_virtual_network.vnet.name
}