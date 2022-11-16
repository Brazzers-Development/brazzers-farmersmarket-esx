
-- @param src - players source
-- @param msg - locale string
-- @param type - 'error' / 'success'
-- @param value - if the locale has a value, we push it through this param
function notification(src, msg, type, value)
    local Player = ESX.GetPlayerFromId(src)

    if value then return Player.showNotification(TranslateCap(msg, value), type) end
    Player.showNotification(TranslateCap(msg), type)
end