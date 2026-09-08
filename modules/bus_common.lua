--- Общие правила для настраиваемых шинных компонентов.

local api       = require("wire_mod_2:api")
local cfg_check = require("advanced_logic_2:configurator_check")

---@class ALBusCommon
local M = {}

M.WIDTHS = {1, 4, 8, 16}
M.DEFAULT_WIDTH = 4

---@param value number|nil
---@return integer
function M.safe_width(value)
    value = math.floor(value or 0)
    for _, width in ipairs(M.WIDTHS) do
        if value == width then return width end
    end
    return M.DEFAULT_WIDTH
end

---@param width integer
---@return integer
function M.next_width(width)
    width = M.safe_width(width)
    for index, candidate in ipairs(M.WIDTHS) do
        if candidate == width then
            return M.WIDTHS[index % #M.WIDTHS + 1]
        end
    end
    return M.DEFAULT_WIDTH
end

---@param width integer
---@return integer
function M.mask(width)
    return 2 ^ M.safe_width(width) - 1
end

---@param value number|nil
---@param width integer
---@return integer
function M.clamp(value, width)
    local modulus = M.mask(width) + 1
    return math.floor(value or 0) % modulus
end

---@param x integer
---@param y integer
---@param z integer
---@return integer
function M.get_width(x, y, z)
    return M.safe_width(block.get_field(x, y, z, "data_bits", 0))
end

---@param x integer
---@param y integer
---@param z integer
function M.init_width(x, y, z)
    local current = block.get_field(x, y, z, "data_bits", 0)
    if current == nil or M.safe_width(current) ~= current then
        block.set_field(x, y, z, "data_bits", M.DEFAULT_WIDTH, 0)
    end
end

---Переключает ширину только конфигуратором в Viewer-режиме.
---@return boolean handled
function M.try_cycle_width(x, y, z, playerid)
    return require('advanced_logic_2:component_settings').open(x,y,z,playerid)
end

---@param width integer
---@return table
function M.viewer_width(width)
    return {
        name = "Ширина",
        value = tostring(M.safe_width(width)) .. " бит",
        color = "#66CCFF",
    }
end

return M
