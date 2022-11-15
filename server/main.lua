local function resetBooth(k)
    Config.Market[k]['owner'] = nil
    Config.Market[k]['groupMembers'] = {}
    Config.Market[k]['password'] = nil
    Config.Market[k]['boothDUI']['url'] = Config.DefaultImage
    TriggerClientEvent('brazzers-market:client:resetMarkets', -1, k)
    CreateThread(function()
        if Config.WipeStashOnLeave then
            exports.ox_inventory:ClearInventory('market_stash'..k, '')
            exports.ox_inventory:ClearInventory('market_pickup'..k, '')
        end
    end)
end

RegisterNetEvent('brazzers-market:server:setOwner', function(market, password)
    local src = source
    local Player = ESX.GetPlayerFromId(src)
    if not Player then return end
    if not market or not password then return end

    local CID = src

    if Config.Market[market]['owner'] then return notification(src, "already_claimed", 'error') end

    if not Config.AllowMultipleClaims then
        for _, v in pairs(Config.Market) do
            if v['owner'] == CID then
                notification(src, "existing_booth", 'error')
                return
            end
        end
    end

    -- Set Owner
    Config.Market[market]['owner'] = CID
    TriggerClientEvent("brazzers-market:client:updateBooth", -1, market, 'owner', CID)
    TriggerClientEvent('brazzers-market:client:setVariable', src, true)
    -- Set Password
    Config.Market[market]['password'] = password
    TriggerClientEvent("brazzers-market:client:setBoothPassword", -1, market, password)
    -- Notification
    notification(src, "booth_claimed")
end)

RegisterNetEvent('brazzers-market:server:setGroupMembers', function(market)
    local src = source
    local Player = ESX.GetPlayerFromId(src)
    if not Player then return end
    if not market then return end

    local CID = src
    local charName = Player.name

    if CID == Config.Market[market]['owner'] then return notification(src, "already_part", 'error') end
    for marketType, _ in pairs(Config.Market) do
        for groupMember, _ in pairs(Config.Market[marketType]['groupMembers']) do
            if Config.Market[marketType]['groupMembers'][groupMember] == CID then
                notification(src, "already_part", 'error')
                return
            end
        end
    end

    -- Update Group Members Table
    Config.Market[market]['groupMembers'][#Config.Market[market]['groupMembers']+1] = CID
    TriggerClientEvent('brazzers-market:client:updateBooth', -1, market, 'groupMembers', json.encode(Config.Market[market]['groupMembers']))
    TriggerClientEvent('brazzers-market:client:setVariable', src, true)
    --Notification
    notification(src, "joined_booth")
    notification(Config.Market[market]['owner'], "global_joined_booth", 'primary', charName)
end)

RegisterNetEvent('brazzers-market:server:leaveBooth', function(market)
    local src = source
    local Player = ESX.GetPlayerFromId(src)
    if not Player then return end
    if not market then return end

    local CID = src
    local charName = Player.name

    if Config.Market[market]['owner'] == CID then
        notification(src, "disband_group")
        resetBooth(market)
        return
    end
    if not next(Config.Market[market]['groupMembers']) then return notification(src, "not_part", 'error') end
    for _, k in pairs(Config.Market[market]['groupMembers']) do
        if k ~= CID then
            notification(src, "not_part", 'error')
            return
        end
    end

    -- Get Current Members & Remove The One Leaving
    local currentGroupMembers = {}
    if Config.Market[market]['groupMembers'] then
        for k, _ in pairs(Config.Market[market]['groupMembers']) do
            if Config.Market[market]['groupMembers'][k] ~= CID then
                currentGroupMembers[#currentGroupMembers+1] = Config.Market[market]['groupMembers'][k]
            end
        end
    end

    -- Update Group Members Table
    Config.Market[market]['groupMembers'] = currentGroupMembers
    TriggerClientEvent('brazzers-market:client:updateBooth', -1, market, 'groupMembers', json.encode(Config.Market[market]['groupMembers']))
    TriggerClientEvent('brazzers-market:client:setVariable', src, false)
    -- Notification
    notification(src, "left_booth")
    notification(Config.Market[market]['owner'], "global_left_booth", 'primary', charName)
end)

RegisterNetEvent('brazzers-market:server:setBannerImage', function(market, url)
    local src = source
    local Player = ESX.GetPlayerFromId(src)
    if not Player then return end
    if not market or not url then return end

    Config.Market[market]['boothDUI']['url'] = url
    TriggerClientEvent('brazzers-market:client:setBannerImage', -1, market, url)
end)

-- Callbacks

ESX.RegisterServerCallback('brazzers-market:server:groupMembers', function(source, cb, market)
    local src = source
    local Player = ESX.GetPlayerFromId(src)
    if not Player then return end

    local CID = src
    local groupOwner = false
    local groupMember = false

    if Config.Market[market]['owner'] == CID then groupOwner = true end
    for _, k in pairs(Config.Market[market]['groupMembers']) do
        if k == CID then
            groupMember = true
        end
    end
    cb(groupOwner, groupMember)
end)

ESX.RegisterServerCallback('brazzers-market:server:getMarketDui', function(_, cb)
    cb(Config.Market)
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local Player = ESX.GetPlayerFromId(playerId)

    if Player then
        for k, _ in pairs(Config.Market) do
            if Config.Market[k]['owner'] == playerId then
                resetBooth(k)
            end
        end
    end
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k, _ in pairs(Config.Market) do
            exports.ox_inventory:RegisterStash('market_stash'..k, 'Market Stash', Config.StashSlots, Config.StashWeight, false)
            exports.ox_inventory:RegisterStash('market_pickup'..k, 'Pickup', Config.PickupSlots, Config.PickupWeight, false)
        end
    end
end)