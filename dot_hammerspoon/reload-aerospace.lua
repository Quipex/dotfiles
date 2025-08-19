-- ~/.hammerspoon/aerospace_reload.lua
local M = {}

-- Полный путь к бинарю aerospace (с твоей системы)
local AEROSPACE = "/opt/homebrew/bin/aerospace"

local function fileExists(path)
    local attr = hs.fs.attributes(path)
    return attr ~= nil and (attr.mode == "file" or attr.mode == "link")
end

function M.reload()
    if not fileExists(AEROSPACE) then
        hs.alert.show("Не найден aerospace: " .. AEROSPACE)
        return
    end

    -- Выполняем команду перезагрузки конфига
    local _, ok, _, rc = hs.execute(AEROSPACE .. " reload-config", true)

    if ok then
        hs.alert.show("AeroSpace конфиг перезагружен")
    else
        hs.alert.show("Ошибка перезагрузки AeroSpace (код " .. tostring(rc) .. ")")
    end
end

return M
