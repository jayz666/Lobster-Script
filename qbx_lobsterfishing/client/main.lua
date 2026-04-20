local QBCore = exports['qbx_core']:GetCoreObject()
local isPlacingTrap = false
local isHarvesting = false
local placedTraps = {}
local playerSkill = 0

-- Functions
function ShowNotification(message, type)
    if Config.Notify.type == 'ox_lib' then
        lib.notify({
            title = 'Lobster Fishing',
            description = message,
            type = type or 'info',
            position = Config.Notify.position
        })
    elseif Config.Notify.type == 'qb-ui' then
        TriggerEvent('QBCore:Notify', message, type)
    else
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            multiline = true,
            args = {'Lobster Fishing', message}
        })
    end
end

function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

function IsInFishingArea()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, area in ipairs(Config.FishingAreas) do
        local distance = #(playerCoords - area.coords)
        if distance <= area.radius then
            return area
        end
    end
    return false
end

function CanPlaceTrap()
    local area = IsInFishingArea()
    if not area then
        ShowNotification('You must be in a designated fishing area to place traps!', 'error')
        return false
    end
    
    local trapCount = 0
    for _, trap in ipairs(placedTraps) do
        if trap.area == area.name then
            trapCount = trapCount + 1
        end
    end
    
    if trapCount >= area.maxTraps then
        ShowNotification(string.format('Maximum traps (%d) already placed in this area!', area.maxTraps), 'error')
        return false
    end
    
    return true, area
end

function PlaceTrap()
    if isPlacingTrap then return end
    
    local canPlace, area = CanPlaceTrap()
    if not canPlace then return end
    
    -- Check if player has trap
    QBCore.Functions.TriggerCallback('qbx_lobsterfishing:hasItem', function(hasItem)
        if not hasItem then
            ShowNotification('You need a lobster trap!', 'error')
            return
        end
        
        isPlacingTrap = true
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Play animation
        LoadAnimDict(Config.Animations.placingTrap.dict)
        TaskPlayAnim(playerPed, Config.Animations.placingTrap.dict, Config.Animations.placingTrap.anim, 8.0, -8.0, Config.Animations.placingTrap.time, 1, 0, false, false, false)
        
        -- Progress bar
        if lib.progressBar({
            duration = Config.Animations.placingTrap.time,
            label = 'Placing lobster trap...',
            useWhileDead = false,
            canCancel = true,
        }) then
            -- Create trap prop
            local trapCoords = playerCoords + vector3(0.0, 0.5, -0.5)
            local trapHeading = GetEntityHeading(playerPed)
            
            local trapProp = CreateObject(GetHashKey(Config.Animations.trapProp), trapCoords.x, trapCoords.y, trapCoords.z, false, false, false)
            SetEntityHeading(trapProp, trapHeading)
            PlaceObjectOnGroundProperly(trapProp)
            
            -- Store trap data
            local trapData = {
                id = #placedTraps + 1,
                coords = trapCoords,
                area = area.name,
                placedTime = GetGameTimer(),
                prop = trapProp,
                harvested = false
            }
            
            table.insert(placedTraps, trapData)
            
            -- Remove trap from inventory
            TriggerServerEvent('qbx_lobsterfishing:removeItem', 'lobster_trap', 1)
            
            ShowNotification('Lobster trap placed! Wait ' .. (Config.Fishing.trapWaitTime / 60000) .. ' minutes before harvesting.', 'success')
        else
            ShowNotification('Cancelled placing trap.', 'error')
        end
        
        ClearPedTasks(playerPed)
        isPlacingTrap = false
    end, 'lobster_trap')
end

function HarvestTrap(trap)
    if isHarvesting then return end
    
    local waitTime = Config.Fishing.trapWaitTime - (GetGameTimer() - trap.placedTime)
    if waitTime > 0 then
        ShowNotification(string.format('Wait %.1f more minutes before harvesting!', waitTime / 60000), 'error')
        return
    end
    
    if trap.harvested then
        ShowNotification('This trap has already been harvested!', 'error')
        return
    end
    
    isHarvesting = true
    local playerPed = PlayerPedId()
    
    -- Play animation
    LoadAnimDict(Config.Animations.harvestingTrap.dict)
    TaskPlayAnim(playerPed, Config.Animations.harvestingTrap.dict, Config.Animations.harvestingTrap.anim, 8.0, -8.0, Config.Animations.harvestingTrap.time, 1, 0, false, false, false)
    
    -- Progress bar
    if lib.progressBar({
        duration = Config.Animations.harvestingTrap.time,
        label = 'Harvesting lobster trap...',
        useWhileDead = false,
        canCancel = true,
    }) then
        -- Calculate catch with skill bonuses
        local catchChance = Config.Fishing.baseCatchChance
        local rareChance = Config.Items.rare_lobster.chance / 100
        
        if Config.Skills.enabled then
            catchChance = catchChance + (playerSkill * Config.Skills.skillMultiplier)
            local skillBonus = Config.Skills.bonuses[playerSkill]
            if skillBonus then
                catchChance = catchChance + skillBonus.catchBonus
                rareChance = rareChance + skillBonus.rareBonus
            end
        end
        
        -- Determine catch
        local lobstersCaught = 0
        local rareLobstersCaught = 0
        
        for i = 1, Config.Fishing.maxLobstersPerTrap do
            if math.random() <= catchChance then
                if math.random() <= rareChance then
                    rareLobstersCaught = rareLobstersCaught + 1
                else
                    lobstersCaught = lobstersCaught + 1
                end
            end
        end
        
        -- Give items to player
        if lobstersCaught > 0 or rareLobstersCaught > 0 then
            TriggerServerEvent('qbx_lobsterfishing:giveLobsters', lobstersCaught, rareLobstersCaught)
            
            -- Add skill XP
            if Config.Skills.enabled then
                local xpGained = (lobstersCaught * Config.Skills.xpPerCatch) + (rareLobstersCaught * Config.Skills.xpPerRareCatch)
                TriggerServerEvent('qbx_lobsterfishing:addSkillXP', xpGained)
            end
            
            local message = string.format('Harvested %d lobsters', lobstersCaught)
            if rareLobstersCaught > 0 then
                message = message .. string.format(' and %d rare lobsters!', rareLobstersCaught)
            end
            ShowNotification(message, 'success')
        else
            ShowNotification('No lobsters in this trap. Try using bait next time!', 'info')
        end
        
        -- Mark trap as harvested and remove prop
        trap.harvested = true
        DeleteObject(trap.prop)
        
        -- Return trap to inventory
        TriggerServerEvent('qbx_lobsterfishing:giveItem', 'lobster_trap', 1)
        
    else
        ShowNotification('Cancelled harvesting trap.', 'error')
    end
    
    ClearPedTasks(playerPed)
    isHarvesting = false
end

function SetupShops()
    for _, shop in ipairs(Config.Shops) do
        exports.ox_target:addBoxZone({
            coords = shop.coords.xyz,
            size = vector3(1.5, 1.5, 2.0),
            rotation = shop.coords.w,
            options = {
                {
                    icon = 'fas fa-shopping-basket',
                    label = 'Open Bait Shop',
                    onSelect = function()
                        OpenShop(shop.name)
                    end
                }
            }
        })
        
        -- Create blip
        if shop.blip then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, shop.blip.sprite)
            SetBlipColour(blip, shop.blip.color)
            SetBlipScale(blip, shop.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(shop.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end

function SetupMarkets()
    for _, market in ipairs(Config.Markets) do
        exports.ox_target:addBoxZone({
            coords = market.coords.xyz,
            size = vector3(1.5, 1.5, 2.0),
            rotation = market.coords.w,
            options = {
                {
                    icon = 'fas fa-dollar-sign',
                    label = 'Sell Lobsters',
                    onSelect = function()
                        SellLobsters()
                    end
                }
            }
        })
        
        -- Create blip
        if market.blip then
            local blip = AddBlipForCoord(market.coords.x, market.coords.y, market.coords.z)
            SetBlipSprite(blip, market.blip.sprite)
            SetBlipColour(blip, market.blip.color)
            SetBlipScale(blip, market.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(market.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end

function OpenShop(shopName)
    local shopItems = {
        {
            title = 'Lobster Trap',
            description = '$' .. Config.Items.lobster_trap.price,
            metadata = {price = Config.Items.lobster_trap.price},
            onSelect = function()
                TriggerServerEvent('qbx_lobsterfishing:buyItem', 'lobster_trap', 1)
            end
        },
        {
            title = 'Fish Bait',
            description = '$' .. Config.Items.bait.price,
            metadata = {price = Config.Items.bait.price},
            onSelect = function()
                TriggerServerEvent('qbx_lobsterfishing:buyItem', 'bait', 1)
            end
        }
    }
    
    lib.showContext({
        id = 'lobster_shop',
        title = shopName,
        options = shopItems
    })
end

function SellLobsters()
    QBCore.Functions.TriggerCallback('qbx_lobsterfishing:getLobsterCount', function(lobsterCount, rareLobsterCount)
        if lobsterCount == 0 and rareLobsterCount == 0 then
            ShowNotification('You don\'t have any lobsters to sell!', 'error')
            return
        end
        
        local totalPrice = (lobsterCount * Config.Items.lobster.price) + (rareLobsterCount * Config.Items.rare_lobster.price)
        
        lib.showContext({
            id = 'sell_lobsters',
            title = 'Seafood Market',
            options = {
                {
                    title = string.format('Sell %d Regular Lobsters ($%d each)', lobsterCount, Config.Items.lobster.price),
                    description = 'Total: $' .. (lobsterCount * Config.Items.lobster.price),
                    onSelect = function()
                        TriggerServerEvent('qbx_lobsterfishing:sellLobsters', 'lobster', lobsterCount)
                    end
                },
                {
                    title = string.format('Sell %d Rare Lobsters ($%d each)', rareLobsterCount, Config.Items.rare_lobster.price),
                    description = 'Total: $' .. (rareLobsterCount * Config.Items.rare_lobster.price),
                    onSelect = function()
                        TriggerServerEvent('qbx_lobsterfishing:sellLobsters', 'rare_lobster', rareLobsterCount)
                    end
                },
                {
                    title = 'Sell All Lobsters',
                    description = 'Total: $' .. totalPrice,
                    onSelect = function()
                        TriggerServerEvent('qbx_lobsterfishing:sellAllLobsters')
                    end
                }
            }
        })
    end)
end

function SetupTrapTargets()
    for _, trap in ipairs(placedTraps) do
        if not trap.harvested then
            exports.ox_target:addSphereZone({
                coords = trap.coords,
                radius = 1.0,
                options = {
                    {
                        icon = 'fas fa-fish',
                        label = 'Harvest Trap',
                        onSelect = function()
                            HarvestTrap(trap)
                        end
                    }
                }
            })
        end
    end
end

-- Events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.TriggerCallback('qbx_lobsterfishing:getSkillLevel', function(skillLevel)
        playerSkill = skillLevel
    end)
end)

RegisterNetEvent('qbx_lobsterfishing:client:updateSkill', function(newLevel)
    playerSkill = newLevel
    ShowNotification(string.format('Lobster Fishing skill increased to level %d!', newLevel), 'success')
end)

function SetupFishingAreaTargets()
    for _, area in ipairs(Config.FishingAreas) do
        exports.ox_target:addSphereZone({
            coords = area.coords,
            radius = area.radius,
            options = {
                {
                    icon = 'fas fa-anchor',
                    label = 'Place Lobster Trap',
                    onSelect = function()
                        PlaceTrap()
                    end,
                    canInteract = function()
                        return IsInFishingArea() ~= false
                    end
                }
            }
        })
    end
end

-- Threads
CreateThread(function()
    SetupShops()
    SetupMarkets()
    SetupFishingAreaTargets()
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Check if player is near any trap
        for _, trap in ipairs(placedTraps) do
            if not trap.harvested then
                local distance = #(playerCoords - trap.coords)
                if distance < 3.0 then
                    sleep = 0
                    -- Draw marker for trap
                    DrawMarker(27, trap.coords.x, trap.coords.y, trap.coords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 100, false, false, 2, false, nil, nil, false)
                end
            end
        end
        
        -- Check if player is in fishing area
        local area = IsInFishingArea()
        if area then
            sleep = 0
            -- Draw area indicator
            DrawMarker(1, area.coords.x, area.coords.y, area.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, area.radius * 2, area.radius * 2, 1.0, 0, 255, 0, 50, false, false, 2, false, nil, nil, false)
        end
        
        Wait(sleep)
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Remove all trap props
    for _, trap in ipairs(placedTraps) do
        if DoesEntityExist(trap.prop) then
            DeleteObject(trap.prop)
        end
    end
end)
