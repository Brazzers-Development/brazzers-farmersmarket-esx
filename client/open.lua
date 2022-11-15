function isMarketOpen()
    return true
end

function notification(msg, type)
    ESX.ShowNotification(TranslateCap(msg), type)
end