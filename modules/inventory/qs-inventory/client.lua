if GetResourceState('qs-inventory') ~= 'started' then return end
local quasar = exports["qs-inventory"]

Inventory = Inventory or {}

Inventory.OpenStash = function(id)
    quasar:RegisterStash(id, 50, 50000)
end

Inventory.GetItemInfo = function(item)
    local itemData = quasar:GetItemList()
    if not itemData[item] then return {} end
    local repackedTable = {
        name = itemData.name or "Missing Name",
        label = itemData.label or "Missing Label",
        stack = itemData.unique or "false",
        weight = itemData.weight or "0",
        description = itemData.description or "none",
        image = itemData.image or Inventory.GetImagePath(item),
    }
    return repackedTable
end

Inventory.HasItem = function(item)
    local check = quasar:Search(item)
    if check ~= 0 then return true else return false end -- if item count isn't 0, returns true, else return false
end

Inventory.GetImagePath = function(item)
    local file = LoadResourceFile("qs-inventory", string.format("html/images/%s.png", item))
    local imagePath = file and string.format("nui://qs-inventory/html/images/%s.png", item)
    return imagePath or "https://avatars.githubusercontent.com/u/47620135"
end

Inventory.GetPlayerInventory = function()
    local items = {}
    local inventory = quasar:getUserInventory()
    for _, v in pairs(inventory) do
        table.insert(items, {
            name = v.name,
            label = v.label,
            count = v.amount,
            slot = v.slot,
            metadata = v.info,
            stack = v.unique,
            close = v.useable,
            weight = v.weight
        })
    end
    return items
end

