
RegisterNetEvent('ox_inventory:updateItem', function(item, slot)
    local playerId = source
    exports.ox_inventory:SetMetadata(playerId, item.name, slot, { durability = item.metadata.durability })
end)


RegisterNetEvent('ox_inventory:removeItem', function(itemName, count, slot)
    local playerId = source
    exports.ox_inventory:RemoveItem(playerId, itemName, count, slot)
end)