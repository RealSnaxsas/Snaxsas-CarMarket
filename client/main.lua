local SpawnedVehicles = {}
local MarketNPC = nil

local function spawnMarketNPC()
    local model = GetHashKey(Config.NPC.model)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    if MarketNPC ~= nil and DoesEntityExist(MarketNPC) then
        DeleteEntity(MarketNPC)
    end

    MarketNPC = CreatePed(4, model, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.coords.w, false, true)
    
    SetEntityAsMissionEntity(MarketNPC, true, true)
    SetBlockingOfNonTemporaryEvents(MarketNPC, true)
    SetEntityInvincible(MarketNPC, true)
    FreezeEntityPosition(MarketNPC, true)
    SetPedCanRagdoll(MarketNPC, false)
    SetPedCanRagdollFromPlayerImpact(MarketNPC, false)
    SetPedCombatAttributes(MarketNPC, 46, true)
    
    TaskStartScenarioInPlace(MarketNPC, "WORLD_HUMAN_CLIPBOARD", 0, true)
end

function refreshLot()
    for k, v in pairs(SpawnedVehicles) do
        if DoesEntityExist(v) then
            DeleteVehicle(v)
        end
    end
    SpawnedVehicles = {}

    ESX.TriggerServerCallback("Snaxsas_script:getMarketVehicles", function(vehicles)
        if vehicles then
            for _, data in ipairs(vehicles) do
                local props = json.decode(data.vehicle_props)
                local slot = Config.Slots[data.slot_id]
                
                if slot then
                    ESX.Game.SpawnLocalVehicle(props.model, slot.coords, slot.heading, function(veh)
                        ESX.Game.SetVehicleProperties(veh, props)
                        SetEntityInvincible(veh, true)
                        SetVehicleDoorsLocked(veh, 2)
                        FreezeEntityPosition(veh, true)
                        SetVehicleNumberPlateText(veh, data.plate)
                        
                        SpawnedVehicles[data.id] = veh
                    end)
                end
            end
        end
    end)
end

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(xPlayer)
    Wait(2000)
    refreshLot()
end)

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(1000)
        refreshLot()
    end
end)

CreateThread(function()
    local blip = AddBlipForCoord(Config.MarketLocation)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.label)
    EndTextCommandSetBlipName(blip)

    spawnMarketNPC()
    refreshLot() 
end)

RegisterNetEvent("Snaxsas_script:refreshVehicles", function()
    refreshLot()
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        local distNPC = #(coords - vector3(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z))
        if distNPC < 3.0 then
            sleep = 0
            ESX.ShowHelpNotification(Config.Locales["sell_car"])
            if IsControlJustReleased(0, 38) then
                openSellMenu()
            end
        elseif distNPC < 50.0 and (MarketNPC == nil or not DoesEntityExist(MarketNPC)) then
            spawnMarketNPC()
        end

        for id, veh in pairs(SpawnedVehicles) do
            if DoesEntityExist(veh) then
                local vehCoords = GetEntityCoords(veh)
                local distVeh = #(coords - vehCoords)
                if distVeh < 3.5 then
                    sleep = 0
                    drawText3D(vehCoords.x, vehCoords.y, vehCoords.z + 1.2, Config.Locales["inspect_car"])
                    if IsControlJustReleased(0, 38) then
                        openBuyMenu(id)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

function openSellMenu()
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
        ESX.ShowNotification(Config.Locales["no_vehicle"])
        return
    end

    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local props = ESX.Game.GetVehicleProperties(vehicle)

    ESX.UI.Menu.Open("dialog", GetCurrentResourceName(), "sell_price", {
        title = "Pardavimo kaina ($)"
    }, function(data, menu)
        local price = tonumber(data.value)
        if not price or price <= 0 then
            ESX.ShowNotification("Neteisinga kaina")
        else
            menu.close()
            ESX.TriggerServerCallback("Snaxsas_script:sellVehicle", function(success)
                if success then
                    ESX.Game.DeleteVehicle(vehicle)
                    ESX.ShowNotification(Config.Locales["listed_for"] .. price)
                end
            end, props.plate, props, price)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function openBuyMenu(marketId)
    ESX.TriggerServerCallback("Snaxsas_script:getMarketVehicles", function(vehicles)
        local data = nil
        for _, v in ipairs(vehicles) do
            if v.id == marketId then data = v break end
        end
        if not data then return end

        local props = json.decode(data.vehicle_props)
        
        local engine = props.modEngine or -1
        local brakes = props.modBrakes or -1
        local trans = props.modTransmission or -1
        
        local elements = {
            {label = "Kaina: <span style='color:green;'>$" .. data.price .. "</span>", value = "none"},
            {label = "--- Techninė būklė ---", value = "none"},
            {label = "Variklis: Lygis " .. (engine + 1), value = "none"},
            {label = "Stabdžiai: Lygis " .. (brakes + 1), value = "none"},
            {label = "Pavarų dėžė: Lygis " .. (trans + 1), value = "none"},
            {label = "Turbo: " .. (props.modTurbo and "Yra" or "Nėra"), value = "none"},
            {label = "--- Veiksmai ---", value = "none"},
            {label = "Patvirtinti pirkimą", value = "buy"}
        }

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "buy_veh", {
            title = "Automobilio apžiūra",
            align = "top-left",
            elements = elements
        }, function(data2, menu2)
            if data2.current.value == "buy" then
                TriggerServerEvent("Snaxsas_script:buyVehicle", marketId)
                menu2.close()
            end
        end, function(data2, menu2)
            menu2.close()
        end)
    end)
end

function drawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end