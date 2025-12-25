local api = require('wire_mod_2:api')

-- Регистрация блока как устройство с 4-битным входом
local device_id = api.register({"advanced_logic_2:seven_segment_display"}, {
    inputs = {
        input = {dir = 0, offset = 1, bits = 4}
    }
})


local FONT_3x5 = {
    [0] = {
        "XXX",
        "X X",
        "X X",
        "X X",
        "XXX",
    },
    [1] = {
        "  X",
        "  X",
        "  X",
        "  X",
        "  X",
    },
    [2] = {
        "XXX",
        "  X",
        "XXX",
        "X  ",
        "XXX",
    },
    [3] = {
        "XXX",
        "  X",
        "XXX",
        "  X",
        "XXX",
    },
    [4] = {
        "X X",
        "X X",
        "XXX",
        "  X",
        "  X",
    },
    [5] = {
        "XXX",
        "X  ",
        "XXX",
        "  X",
        "XXX",
    },
    [6] = {
        "XXX",
        "X  ",
        "XXX",
        "X X",
        "XXX",
    },
    [7] = {
        "XXX",
        "  X",
        "  X",
        "  X",
        "  X",
    },
    [8] = {
        "XXX",
        "X X",
        "XXX",
        "X X",
        "XXX",
    },
    [9] = {
        "XXX",
        "X X",
        "XXX",
        "  X",
        "XXX",
    },
    [10] = { -- A
        "XXX",
        "X X",
        "XXX",
        "X X",
        "X X",
    },
    [11] = { -- b
        "X  ",
        "X  ",
        "XXX",
        "X X",
        "XXX",
    },
    [12] = { -- C
        "XXX",
        "X  ",
        "X  ",
        "X  ",
        "XXX",
    },
    [13] = { -- d
        "  X",
        "  X",
        "XXX",
        "X X",
        "XXX",
    },
    [14] = { -- E
        "XXX",
        "X  ",
        "XXX",
        "X  ",
        "XXX",
    },
    [15] = { -- F
        "XXX",
        "X  ",
        "XXX",
        "X  ",
        "X  ",
    },
}


local function get_vectors(rotation)
    local fx, fz = 0, 1
    if rotation == 1 then fx, fz = 1, 0
    elseif rotation == 2 then fx, fz = 0, -1
    elseif rotation == 3 then fx, fz = -1, 0 end

    local rx, rz = fz, -fx
    return rx, rz
end


local function build_cells(origin_x, origin_y, origin_z, rotation)
    local rx, rz = get_vectors(rotation)

    -- origin = блок гейта
    -- дисплей начинается СРАЗУ НАД ним
    local cx = origin_x
    local cz = origin_z

    local cells = {}

    for row = 0, 4 do
        cells[row] = {}
        local y = origin_y + 1 + row  -- КРИТИЧНО: +1

        for col = 0, 2 do
            local x = cx + col * rx
            local z = cz + col * rz
            cells[row][col] = { x = x, y = y, z = z }
        end
    end

    return cells
end



local function update_display(origin_x, origin_y, origin_z, value)
    local rot = block.get_rotation(origin_x, origin_y, origin_z) or 0
    local cells = build_cells(origin_x, origin_y, origin_z, rot)

    value = math.max(0, math.min(15, value))
    local glyph = FONT_3x5[value]
    if not glyph then return end

    local lamp_on_id  = block.index("wire_mod_2:lamp_on")
    local lamp_off_id = block.index("wire_mod_2:lamp_off")

    for row = 0, 4 do
        local line = glyph[5 - row]
        for col = 0, 2 do
            local on = line:sub(col + 1, col + 1) == "X"
            local p = cells[row][col]

            local current_id = block.get(p.x, p.y, p.z)
            if current_id == lamp_on_id or current_id == lamp_off_id then
                block.set(p.x, p.y, p.z, on and lamp_on_id or lamp_off_id, 0)
            end
        end
    end
end

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    update_display(origin[1], origin[2], origin[3], read("input") or 0)
end)


function on_placed(x, y, z, playerid)
    local ox, oy, oz = block.seek_origin(x, y, z)
    local rot = block.get_rotation(ox, oy, oz) or 0

    local cells = build_cells(ox, oy, oz, rot)
    local lamp_off_id = block.index("wire_mod_2:lamp_off")

    for row = 0, 4 do
        for col = 0, 2 do
            local p = cells[row][col]
            if block.get(p.x, p.y, p.z) == 0 then
                block.set(p.x, p.y, p.z, lamp_off_id, 0)
            end
        end
    end

    api.on_placed(ox, oy, oz, device_id)
    update_display(ox, oy, oz, 0)
end


local function has_lamp(x, y, z)
    local id = block.get(x, y, z)
    return id == block.index("wire_mod_2:lamp_on")
        or id == block.index("wire_mod_2:lamp_off")
end

local function detect_rotation_from_lamps(ox, oy, oz)
    -- проверяем только первый ряд над гейтом (достаточно)
    local y = oy + 1

    -- rotation 0 → +X
    if has_lamp(ox + 1, y, oz) then
        return 0
    end

    -- rotation 1 → -Z
    if has_lamp(ox, y, oz - 1) then
        return 1
    end

    -- rotation 2 → -X
    if has_lamp(ox - 1, y, oz) then
        return 2
    end

    -- rotation 3 → +Z
    if has_lamp(ox, y, oz + 1) then
        return 3
    end

    -- если ничего не нашли — дисплей уже разрушен или повреждён
    return nil
end


function on_broken(x, y, z, playerid)
    local ox, oy, oz = block.seek_origin(x, y, z)

    local rot = detect_rotation_from_lamps(ox, oy, oz)
    if not rot then
        -- дисплей уже разрушен или не найден
        api.on_broken(ox, oy, oz, device_id)
        return
    end

    local cells = build_cells(ox, oy, oz, rot)

    local lamp_on_id  = block.index("wire_mod_2:lamp_on")
    local lamp_off_id = block.index("wire_mod_2:lamp_off")

    for row = 0, 4 do
        for col = 0, 2 do
            local p = cells[row][col]
            local id = block.get(p.x, p.y, p.z)
            if id == lamp_on_id or id == lamp_off_id then
                block.set(p.x, p.y, p.z, 0, 0)
            end
        end
    end

    api.on_broken(ox, oy, oz, device_id)
end
