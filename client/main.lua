local inFarmersMarket = false

-- Functions

exports('inFarmersMarket', function()
    return inFarmersMarket
end)

local function CreateDUI(market, url)
    Config.Market[market]['boothDUI']['dui'] = { obj = CreateDui(url, Config.Market[market]['boothDUI']['width'], Config.Market[market]['boothDUI']['height']) }
    Config.Market[market]['boothDUI']['dui'].dict = ("%s-dict"):format(market)
    Config.Market[market]['boothDUI']['dui'].texture = ("%s-txt"):format(market)
    local dictObject = CreateRuntimeTxd(Config.Market[market]['boothDUI']['dui'].dict)
    local duiHandle = GetDuiHandle(Config.Market[market]['boothDUI']['dui'].obj)
    CreateRuntimeTextureFromDuiHandle(dictObject, Config.Market[market]['boothDUI']['dui'].texture, duiHandle)
    AddReplaceTexture(Config.Market[market]['boothDUI']['ytd'], Config.Market[market]['boothDUI']['ytdname'], Config.Market[market]['boothDUI']['dui'].dict, Config.Market[market]['boothDUI']['dui'].texture)
end

local function removeDUI(market, removeAll)
    if not Config.Market[market]['boothDUI']['dui'] then return end
    SetDuiUrl(Config.Market[market]['boothDUI']['dui'].obj, Config.DefaultImage)
    if removeAll then
        DestroyDui(Config.Market[market]['boothDUI']['dui'].obj)
        RemoveReplaceTexture(Config.Market[market]['boothDUI']['ytd'], Config.Market[market]['boothDUI']['ytdname'])
    end
    Config.Market[market]['boothDUI']['dui'] = nil
end

local function setupDUI()
    ESX.TriggerServerCallback('brazzers-market:server:getMarketDui',function(DUIs)
        Config.Market = DUIs
    end)

    local pierZone = CircleZone:Create(Config.PierPoly, Config.PierRadius, {
        name = "pier_market_zone",
        debugPoly = Config.Debug
    })

    pierZone:onPlayerInOut(function(isPointInside, _)
        if isPointInside then
            for k, _ in pairs(Config.Market) do
                CreateDUI(k, Config.Market[k]['boothDUI']['url'])
            end
        else
            for k, _ in pairs(Config.Market) do
                removeDUI(k, true)
            end
        end
    end)
end

local function claimBooth(k)
    if not isMarketOpen() then return notification("market_not_open", "error") end
    if Config.Market[k]['owner'] then return notification("already_claimed", "error") end
    
    local input = lib.inputDialog("Set Booth Password", {"Password"})
    if not input then return end
    
    password = tonumber(input[1])
    if not password then return notification("password_not_number", "error") end
    
    TriggerServerEvent('brazzers-market:server:setOwner', k, password)
end

local function leaveBooth(k)
    TriggerServerEvent('brazzers-market:server:leaveBooth', k)
end

local function joinBooth(k)
    if not isMarketOpen() then return notification("market_not_open", "error") end
    if not Config.Market[k]['owner'] then return notification("not_claimed", "error") end

    local input = lib.inputDialog("Input Booth Password", {'Password'})
    if not input then return end

    password = tonumber(input[1])
    if not password then return notification("password_not_number", "error") end

    if password ~= Config.Market[k]['password'] then return notification("incorrect_password", "error") end
    TriggerServerEvent('brazzers-market:server:setGroupMembers', k)
end

local function changeBanner(k)
    if not isMarketOpen() then return notification("market_not_open", "error") end
    ESX.TriggerServerCallback('brazzers-market:server:groupMembers', function(IsOwner, IsInGroup)
        if IsOwner or IsInGroup then
            local input = lib.inputDialog("Change Banner", {"Imgur (1024x1024"})
            if not input then return end

            banner = input[1]
            if not banner then return end
            TriggerServerEvent('brazzers-market:server:setBannerImage', k, banner)
        end
    end, k)
end

local function marketStash(k)
    if not isMarketOpen() then return notification("market_not_open", "error") end
    ESX.TriggerServerCallback('brazzers-market:server:groupMembers', function(IsOwner, IsInGroup)
        if IsOwner or IsInGroup then
            exports.ox_inventory:openInventory('stash', {id='market_stash'..k, owner=false})
        end
    end, k)
end

local function marketPickup(k)
    exports.ox_inventory:openInventory('stash', {id='market_pickup'..k, owner=false})
end

-- Net Events

RegisterNetEvent('brazzers-market:client:updateBooth', function(market, type, citizenid)
    Config.Market[market][type] = citizenid
end)

RegisterNetEvent('brazzers-market:client:setBoothPassword', function(market, password)
    Config.Market[market]['password'] = password
end)

RegisterNetEvent('brazzers-market:client:resetMarkets', function(market)
    Config.Market[market]['owner'] = nil
    Config.Market[market]['groupMembers'] = {}
    Config.Market[market]['password'] = nil
    Config.Market[market]['boothDUI']['url'] = Config.DefaultImage
    removeDUI(market, false)
end)

RegisterNetEvent('brazzers-market:client:setVariable', function(variable)
    inFarmersMarket = variable
end)

RegisterNetEvent('brazzers-market:client:setBannerImage', function(market, url)
    Config.Market[market]['boothDUI']['url'] = url

    if Config.Market[market]['boothDUI']['dui'] then
        SetDuiUrl(Config.Market[market]['boothDUI']['dui'].obj, Config.Market[market]['boothDUI']['url'])
    else
        CreateDUI(market, url)
    end
end)

-- Threads

CreateThread(function()
    setupDUI()
end)

CreateThread(function()
    for k, v in pairs(Config.Market) do
        exports[Config.Target]:AddBoxZone("market_booth_"..k, v['booth']['coords'].xyz, 1.0, 3.0, {
            name = "market_booth_"..k,
            heading = v['booth']['heading'],
            debugPoly = Config.Debug,
            minZ = v['booth']['coords'].z,
            maxZ = v['booth']['coords'].z + 1.5,
            }, {
                options = {
                {
                    action = function()
                        claimBooth(k)
                    end,
                    icon = 'fas fa-flag',
                    label = 'Claim Booth',
                    canInteract = function()
                        if isMarketOpen() then
                            return true
                        end
                    end,
                },
                {
                    action = function()
                        leaveBooth(k)
                    end,
                    icon = 'fas fa-flag',
                    label = 'Leave Booth',
                    canInteract = function()
                        if isMarketOpen() and Config.Market[k]['owner'] then
                            return true
                        end
                    end,
                },
                {
                    action = function()
                        joinBooth(k)
                    end,
                    icon = 'fas fa-circle',
                    label = 'Join Booth',
                    canInteract = function()
                        if isMarketOpen() and Config.Market[k]['owner'] then
                            return true
                        end
                    end,
                },
                {
                    action = function()
                        changeBanner(k)
                    end,
                    icon = 'fas fa-recycle',
                    label = 'Change Banner',
                    canInteract = function()
                        if isMarketOpen() and Config.Market[k]['owner'] then
                            return true
                        end
                    end,
                },
            },
            distance = 1.0,
        })

        exports[Config.Target]:AddBoxZone("market_register_"..k, v['register']['coords'].xyz, 1.5, 1.0, {
            name = "market_register_"..k,
            heading = v['register']['heading'],
            debugPoly = Config.Debug,
            minZ = v['register']['coords'].z - 1.0,
            maxZ = v['register']['coords'].z + 1.0,
            }, {
                options = {
                {
                    action = function()
                        marketStash(k)
                    end,
                    icon = 'fas fa-box',
                    label = 'Inventory',
                    canInteract = function()
                        if isMarketOpen() and Config.Market[k]['owner'] then
                            return true
                        end
                    end,
                },
                {
                    action = function()
                        marketPickup(k)
                    end,
                    icon = 'fas fa-hand-holding',
                    label = 'Pick Up',
                    canInteract = function()
                        if isMarketOpen() and Config.Market[k]['owner'] then
                            return true
                        end
                    end,
                },
            },
            distance = 1.0,
        })
    end
end)