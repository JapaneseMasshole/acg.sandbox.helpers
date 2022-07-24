output "resource_group_name" {
    value = data.azurerm_resource_group.rg.name
}
output "storage_account_name" {
    value = data.azurerm_storage_account.storageacct.name
}