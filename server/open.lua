function notification(src, msg, type, param)
    local Player = ESX.GetPlayerFromId(src)

    if param then return Player.showNotification(TranslateCap(msg, param), type) end
    Player.showNotification(TranslateCap(msg), type)
end