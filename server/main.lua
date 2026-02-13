local MarketVehicles = {}

function LoadMarketVehicles()
    local results = MySQL.query.await("SELECT * FROM used_cars")
    MarketVehicles = results or {}
    print("^2[Used Market] ^0Užkrauta automobilių: " .. #MarketVehicles)
end

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS used_cars (
            id INT AUTO_INCREMENT PRIMARY KEY,
            seller_identifier VARCHAR(60),
            plate VARCHAR(12),
            vehicle_props LONGTEXT,
            price INT,
            slot_id INT
        )
    ]])
    LoadMarketVehicles()
end)

CreateThread(function()
    Wait(1000)
    if #MarketVehicles == 0 then
        LoadMarketVehicles()
    end
end)

ESX.RegisterServerCallback("Snaxsas_script:getMarketVehicles", function(source, cb)
    cb(MarketVehicles)
end)

ESX.RegisterServerCallback("Snaxsas_script:sellVehicle", function(source, cb, plate, props, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end

    local result = MySQL.single.await("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ?", {
        xPlayer.getIdentifier(),
        plate
    })

    if result then
        local slotId = nil
        for i = 1, #Config.Slots do
            local occupied = false
            for _, v in ipairs(MarketVehicles) do
                if v.slot_id == i then 
                    occupied = true 
                    break 
                end
            end
            if not occupied then 
                slotId = i 
                break 
            end
        end

        if not slotId then
            xPlayer.showNotification(Config.Locales["lot_full"])
            return cb(false)
        end

        MySQL.update.await("DELETE FROM owned_vehicles WHERE plate = ?", {plate})
        
        MySQL.insert.await("INSERT INTO used_cars (seller_identifier, plate, vehicle_props, price, slot_id) VALUES (?, ?, ?, ?, ?)", {
            xPlayer.getIdentifier(),
            plate,
            json.encode(props),
            price,
            slotId
        })

        LoadMarketVehicles()
        TriggerClientEvent("Snaxsas_script:refreshVehicles", -1)
        cb(true)
    else
        xPlayer.showNotification(Config.Locales["not_owner"])
        cb(false)
    end
end)

RegisterNetEvent("Snaxsas_script:buyVehicle", function(marketId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local vehicle = MySQL.single.await("SELECT * FROM used_cars WHERE id = ?", {marketId})
    if not vehicle then return end

    if xPlayer.getMoney() >= vehicle.price then
        xPlayer.removeMoney(vehicle.price)
        
        local sellerIdentifier = vehicle.seller_identifier
        local commission = math.floor(vehicle.price * Config.Commission)
        local finalPrice = vehicle.price - commission

        local xSeller = ESX.GetPlayerFromIdentifier(sellerIdentifier)
        if xSeller then
            xSeller.addAccountMoney("bank", finalPrice)
            xSeller.showNotification(string.format(Config.Locales["sold_notify"], vehicle.plate, finalPrice))
        else
            MySQL.update.await("UPDATE users SET bank = bank + ? WHERE identifier = ?", {finalPrice, sellerIdentifier})
        end

        MySQL.insert.await("INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)", {
            xPlayer.getIdentifier(),
            vehicle.plate,
            vehicle.vehicle_props
        })

        MySQL.update.await("DELETE FROM used_cars WHERE id = ?", {marketId})
        
        LoadMarketVehicles()
        TriggerClientEvent("Snaxsas_script:refreshVehicles", -1)
        xPlayer.showNotification(Config.Locales["bought_veh"])
    else
        xPlayer.showNotification(Config.Locales["not_enough_money"])
    end
end)