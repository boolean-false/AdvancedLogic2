--- Проверка наличия logic_configurator у игрока в руке.
--- Используется для гейтинга UI-открытий по специальному инструменту.

local modes = require('wire_mod_2:configurator_modes')

---@class ALConfiguratorCheck
local M = {}

local CONFIGURATOR_ITEM = "wire_mod_2:logic_configurator"

---@param playerid integer
---@return boolean
function M.has_configurator(playerid)
    local invid, slot = player.get_inventory(playerid)
    if not invid or invid == 0 then
        return false
    end

    local itemid, _ = inventory.get(invid, slot)
    if not itemid or itemid == 0 then
        return false
    end

    local ok, name = pcall(item.name, itemid)
    if not ok or not name then
        return false
    end

    return name == CONFIGURATOR_ITEM
end

---Проверка: configurator в руке И активный режим = VIEWER.
---Используется блоками, открывающими UI: они НЕ должны открывать UI в ROUTER-режиме,
---иначе ПКМ конфликтует с anchor-set механикой Wire Router.
---@param playerid integer
---@return boolean
function M.can_open_ui(playerid)
    if not M.has_configurator(playerid) then return false end
    return modes.get_mode(playerid) == modes.MODE_VIEWER
end

return M
