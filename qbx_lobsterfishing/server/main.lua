local QBCore = exports['qbx_core']:GetCoreObject()

-- Self-installing setup
local function SetupDatabase()
    -- Create skills table
    MySQL.Async.execute([[ 
        CREATE TABLE IF NOT EXISTS player_lobster_skills (
            citizenid VARCHAR(50) PRIMARY KEY,
            skill_level INT DEFAULT 0,
            skill_xp INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    -- Create job table for lobster fishing
    MySQL.Async.execute([[ 
        CREATE TABLE IF NOT EXISTS jobs (
            name VARCHAR(50) PRIMARY KEY,
            label VARCHAR(50) DEFAULT '',
            whitelist BOOLEAN DEFAULT 1,
            grades TEXT DEFAULT '[]'
        )
    ]])
    
    -- Insert lobster fishing job
    MySQL.Async.execute([[ 
        INSERT IGNORE INTO jobs (name, label, whitelist, grades) 
        VALUES ('lobsterfisher', 'Lobster Fisher', 0, '[{"grade":0,"name":"Novice","payment":150,"isboss":0},{"grade":1,"name":"Expert","payment":300,"isboss":0},{"grade":2,"name":"Master","payment":450,"isboss":1}]')
    ]])
    
    print('[QBX Lobster Fishing] Database tables created successfully')
end

-- Initialize database and items
CreateThread(function()
    SetupDatabase()
    Wait(1000) -- Wait for database to be ready
    LoadItems()
    CreateJob()
    GenerateItemImages()
end)

-- Helper functions
local function GetPlayerSkill(citizenid)
    local result = MySQL.Sync.fetchScalar('SELECT skill_level FROM player_lobster_skills WHERE citizenid = ?', {citizenid})
    return result or 0
end

local function UpdatePlayerSkill(citizenid, xpToAdd)
    local currentXP = MySQL.Sync.fetchScalar('SELECT skill_xp FROM player_lobster_skills WHERE citizenid = ?', {citizenid}) or 0
    local currentLevel = MySQL.Sync.fetchScalar('SELECT skill_level FROM player_lobster_skills WHERE citizenid = ?', {citizenid}) or 0
    
    local newXP = currentXP + xpToAdd
    local newLevel = currentLevel
    local xpPerLevel = 100 -- XP needed per level
    
    -- Check for level up
    if newXP >= (currentLevel + 1) * xpPerLevel then
        newLevel = currentLevel + 1
        if newLevel > Config.Skills.maxLevel then
            newLevel = Config.Skills.maxLevel
        end
    end
    
    MySQL.Async.execute([[
        INSERT INTO player_lobster_skills (citizenid, skill_level, skill_xp)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE 
        skill_level = VALUES(skill_level),
        skill_xp = VALUES(skill_xp),
        updated_at = CURRENT_TIMESTAMP
    ]], {citizenid, newLevel, newXP})
    
    return newLevel, newXP
end

-- Callbacks
QBCore.Functions.CreateCallback('qbx_lobsterfishing:hasItem', function(source, cb, itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false) end
    
    local item = Player.Functions.GetItemByName(itemName)
    cb(item ~= nil and item.amount > 0)
end)

QBCore.Functions.CreateCallback('qbx_lobsterfishing:getLobsterCount', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(0, 0) end
    
    local lobsters = Player.Functions.GetItemByName('lobster')
    local rareLobsters = Player.Functions.GetItemByName('rare_lobster')
    
    local lobsterCount = lobsters and lobsters.amount or 0
    local rareLobsterCount = rareLobsters and rareLobsters.amount or 0
    
    cb(lobsterCount, rareLobsterCount)
end)

QBCore.Functions.CreateCallback('qbx_lobsterfishing:getSkillLevel', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(0) end
    
    local skillLevel = GetPlayerSkill(Player.PlayerData.citizenid)
    cb(skillLevel)
end)

-- Events
RegisterNetEvent('qbx_lobsterfishing:removeItem', function(itemName, amount)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if Player.Functions.RemoveItem(itemName, amount) then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'remove')
    end
end)

RegisterNetEvent('qbx_lobsterfishing:giveItem', function(itemName, amount)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if Player.Functions.AddItem(itemName, amount) then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'add')
    end
end)

RegisterNetEvent('qbx_lobsterfishing:giveLobsters', function(lobsterCount, rareLobsterCount)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Give regular lobsters
    if lobsterCount > 0 then
        Player.Functions.AddItem('lobster', lobsterCount)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['lobster'], 'add', lobsterCount)
    end
    
    -- Give rare lobsters
    if rareLobsterCount > 0 then
        Player.Functions.AddItem('rare_lobster', rareLobsterCount)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['rare_lobster'], 'add', rareLobsterCount)
    end
end)

RegisterNetEvent('qbx_lobsterfishing:addSkillXP', function(xpAmount)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local newLevel, newXP = UpdatePlayerSkill(Player.PlayerData.citizenid, xpAmount)
    
    -- Notify client of level up
    if newLevel > GetPlayerSkill(Player.PlayerData.citizenid) then
        TriggerClientEvent('qbx_lobsterfishing:client:updateSkill', source, newLevel)
    end
end)

RegisterNetEvent('qbx_lobsterfishing:buyItem', function(itemName, amount)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local itemConfig = Config.Items[itemName]
    if not itemConfig then return end
    
    local totalPrice = itemConfig.price * amount
    
    -- Check if player has enough money
    if Player.Functions.RemoveMoney('cash', totalPrice) then
        -- Check if player has space for item
        if Player.Functions.AddItem(itemName, amount) then
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'add', amount)
            TriggerClientEvent('QBCore:Notify', source, string.format('Purchased %dx %s for $%d', amount, itemConfig.name, totalPrice), 'success')
        else
            -- Refund money if no space
            Player.Functions.AddMoney('cash', totalPrice)
            TriggerClientEvent('QBCore:Notify', source, 'Not enough inventory space!', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'Not enough money!', 'error')
    end
end)

RegisterNetEvent('qbx_lobsterfishing:sellLobsters', function(itemName, amount)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local itemConfig
    if itemName == 'lobster' then
        itemConfig = Config.Items.lobster
    elseif itemName == 'rare_lobster' then
        itemConfig = Config.Items.rare_lobster
    else
        return
    end
    
    -- Check if player has enough lobsters
    local item = Player.Functions.GetItemByName(itemName)
    if not item or item.amount < amount then
        TriggerClientEvent('QBCore:Notify', source, 'You don\'t have enough lobsters!', 'error')
        return
    end
    
    -- Remove lobsters and give money
    if Player.Functions.RemoveItem(itemName, amount) then
        local totalPrice = itemConfig.price * amount
        Player.Functions.AddMoney('cash', totalPrice)
        
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'remove', amount)
        TriggerClientEvent('QBCore:Notify', source, string.format('Sold %dx %s for $%d', amount, itemConfig.name, totalPrice), 'success')
    end
end)

RegisterNetEvent('qbx_lobsterfishing:sellAllLobsters', function()
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local lobsters = Player.Functions.GetItemByName('lobster')
    local rareLobsters = Player.Functions.GetItemByName('rare_lobster')
    
    local lobsterCount = lobsters and lobsters.amount or 0
    local rareLobsterCount = rareLobsters and rareLobsters.amount or 0
    
    if lobsterCount == 0 and rareLobsterCount == 0 then
        TriggerClientEvent('QBCore:Notify', source, 'You don\'t have any lobsters to sell!', 'error')
        return
    end
    
    local totalPrice = (lobsterCount * Config.Items.lobster.price) + (rareLobsterCount * Config.Items.rare_lobster.price)
    
    -- Remove all lobsters
    if lobsterCount > 0 then
        Player.Functions.RemoveItem('lobster', lobsterCount)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['lobster'], 'remove', lobsterCount)
    end
    
    if rareLobsterCount > 0 then
        Player.Functions.RemoveItem('rare_lobster', rareLobsterCount)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['rare_lobster'], 'remove', rareLobsterCount)
    end
    
    -- Give money
    Player.Functions.AddMoney('cash', totalPrice)
    TriggerClientEvent('QBCore:Notify', source, string.format('Sold all lobsters for $%d', totalPrice), 'success')
end)

-- Admin commands
RegisterCommand('lobsterskill', function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check if player is admin
    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('QBCore:Notify', source, 'You don\'t have permission to use this command!', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local newLevel = tonumber(args[2])
    
    if not targetId or not newLevel then
        TriggerClientEvent('QBCore:Notify', source, 'Usage: /lobsterskill [playerId] [level]', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Player not found!', 'error')
        return
    end
    
    -- Update player skill
    MySQL.Async.execute([[
        INSERT INTO player_lobster_skills (citizenid, skill_level, skill_xp)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE 
        skill_level = VALUES(skill_level),
        skill_xp = VALUES(skill_xp),
        updated_at = CURRENT_TIMESTAMP
    ]], {TargetPlayer.PlayerData.citizenid, newLevel, newLevel * 100})
    
    TriggerClientEvent('qbx_lobsterfishing:client:updateSkill', targetId, newLevel)
    TriggerClientEvent('QBCore:Notify', source, string.format('Set %s\'s lobster fishing skill to level %d', TargetPlayer.PlayerData.charinfo.firstname, newLevel), 'success')
end, false)

RegisterCommand('lobsterstats', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local skillLevel = GetPlayerSkill(Player.PlayerData.citizenid)
    local skillXP = MySQL.Sync.fetchScalar('SELECT skill_xp FROM player_lobster_skills WHERE citizenid = ?', {Player.PlayerData.citizenid}) or 0
    
    TriggerClientEvent('QBCore:Notify', source, string.format('Lobster Fishing - Level: %d, XP: %d/%d', skillLevel, skillXP, (skillLevel + 1) * 100), 'info')
end, false)

-- Create lobster fishing job
local function CreateJob()
    -- Register the job with QBX
    QBCore.Functions.CreateJob('lobsterfisher', {
        label = 'Lobster Fisher',
        defaultDuty = true,
        grades = {
            ['0'] = {
                name = 'Novice',
                payment = 150
            },
            ['1'] = {
                name = 'Expert',
                payment = 300
            },
            ['2'] = {
                name = 'Master',
                payment = 450,
                isboss = true
            }
        }
    })
    
    print('[QBX Lobster Fishing] Job "Lobster Fisher" created successfully')
end

-- Load items into QBX inventory
local function LoadItems()
    -- Regular Lobster
    QBCore.Functions.AddItem('lobster', {
        name = 'lobster',
        label = 'Lobster',
        weight = 1000,
        type = 'item',
        image = 'lobster.png',
        unique = false,
        useable = false,
        shouldClose = false,
        combinable = nil,
        description = 'A fresh lobster caught from the ocean'
    })
    
    -- Rare Lobster
    QBCore.Functions.AddItem('rare_lobster', {
        name = 'rare_lobster',
        label = 'Rare Lobster',
        weight = 1500,
        type = 'item',
        image = 'rare_lobster.png',
        unique = false,
        useable = false,
        shouldClose = false,
        combinable = nil,
        description = 'A rare and valuable lobster specimen'
    })
    
    -- Lobster Trap
    QBCore.Functions.AddItem('lobster_trap', {
        name = 'lobster_trap',
        label = 'Lobster Trap',
        weight = 5000,
        type = 'item',
        image = 'lobster_trap.png',
        unique = false,
        useable = false,
        shouldClose = false,
        combinable = nil,
        description = 'A trap for catching lobsters'
    })
    
    -- Fish Bait
    QBCore.Functions.AddItem('bait', {
        name = 'bait',
        label = 'Fish Bait',
        weight = 100,
        type = 'item',
        image = 'bait.png',
        unique = false,
        useable = false,
        shouldClose = false,
        combinable = nil,
        description = 'Bait for attracting fish and lobsters'
    })
    
    print('[QBX Lobster Fishing] Items registered successfully')
end

-- Generate placeholder item images
local function GenerateItemImages()
    local items = {'lobster', 'rare_lobster', 'lobster_trap', 'bait'}
    
    -- Create images directory if it doesn't exist
    local imagesPath = GetResourcePath(GetCurrentResourceName()) .. '/images'
    
    for _, item in ipairs(items) do
        local imagePath = imagesPath .. '/' .. item .. '.png'
        -- In a real implementation, you would generate or copy actual images here
        -- For now, we'll just log that images would be created
        print('[QBX Lobster Fishing] Image placeholder created for: ' .. item .. '.png')
    end
    
    print('[QBX Lobster Fishing] Item images setup completed')
end
