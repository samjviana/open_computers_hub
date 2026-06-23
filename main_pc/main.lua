local component = require("component")
local computer = require("computer")
local sides = require("sides")
local unicode = require("unicode")
local serialization = require("serialization")
local gpu = component.gpu

local redstone_io = component.proxy("8ce8192e-61c3-4da7-b4cf-3f6f0e47e27e")
local rs_interface_0 = component.proxy("015f8bd9-e59e-41e5-9673-044f5cd34150")
local rs_interface_1 = component.proxy("e2ebf32c-a6b3-47c2-9a54-bc3d3975b4e5")

local STOP_SIDE = sides.south
local TRASH_SIDE = sides.south
local CHEST_SIDE = sides.north

local MAX_QUANTITY = 20000

local COW_FEED_COOLDOWN = 600 -- 10 minutes

local function buildProgressBar(prefix, suffix, progress, bar_only)
    bar_only = bar_only or false
    if progress > 1.0 then
        progress = 1.0
    end

    local width, _ = gpu.getResolution()
    width = width - #prefix - #suffix - 2

    local filled = math.floor(progress * width)
    local bar = string.rep("█", filled) .. string.rep("░", width - filled)

    local pad = string.rep(" ", width)
    local text = string.format("%s %s %s", prefix, bar, suffix)

    if bar_only then
        return bar
    end    

    return text
end

local function findItem(item_id)
    local items = rs_interface_0.getItems()
    for i, stack in pairs(items) do
        if stack.name == item_id then
            return stack
        end
    end

    return nil
end

local last_wheat = nil

local COW_COUNT = 15
local WHEAT_CHEST_SIDE = sides.south

local function feedCows()
    local now = computer.uptime()
    if last_wheat ~= nil and  now - last_wheat < COW_FEED_COOLDOWN then
        return
    end

    local wheat = findItem("minecraft:wheat")
    if wheat == nil then
        return
    end

    -- local debug = serialization.serialize(wheat)
    -- print(debug)
    local ret = rs_interface_1.extractItem(wheat, COW_COUNT, WHEAT_CHEST_SIDE)
    if ret then
        last_wheat = now
    end
    -- print("ret = " .. ret)
end

local function startsWith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

os.execute("clear")
local maxWidth, maxHeight = gpu.maxResolution()
gpu.setResolution(math.min(160, maxWidth), math.min(50, maxHeight))

local prefix = "Storage Monitor"
local storage = rs_interface_0.getStorages().total.item
local usage_percentage = storage.usage / storage.capacity
local suffix = string.format("%.2f%% (%d / %d)", usage_percentage * 100, storage.usage, storage.capacity)
local progress_bar = buildProgressBar(prefix, suffix, usage_percentage)

gpu.set(1, 1, progress_bar)

local biggest_name = 0
local biggest_suffix = 0
while redstone_io.getInput(STOP_SIDE) == 0 do
    feedCows()

    local line = 3
    local items = rs_interface_0.getItems()
    table.sort(items, function(a, b)
        return a.size > b.size
    end)
    for i, stack in pairs(items) do
        if not stack or type(stack) ~= "table" then
            goto continue
        end

        local item_id = stack.name
        local name = stack.label or item_id
        local quantity = stack.size
        local percentage = quantity / MAX_QUANTITY
        local durability = stack.maxDamage
        local damage = stack.damage

        if damage > 0 and durability > 0 -- and item_id == "minecraft:diamond_leggings" then
            and not string.find(item_id, "tconstruct")
            and not string.find(item_id, "plustic")
            and not string.find(item_id, "canister")
            and not string.find(item_id, "oxygen_tank")
            and not string.find(item_id, "infusion_crystal")
        then
            -- local debug = serialization.serialize(stack.tag or {}, false)
            -- os.execute("clear")
            -- print(debug)
            -- print()

            local ret = rs_interface_0.extractItem(stack, quantity, CHEST_SIDE)
            -- if ret then
            --     print("Extracted Item")
            -- end           

            -- os.exit()
            goto continue
        end

        if percentage < 0.4 then
            goto continue
        end

        local search = "\u{00A7}e"
        if startsWith(name, search) then
            name = string.sub(name, #search + 1, #name)
            gpu.setForeground(0xFFFF55)
        elseif gpu.getForeground() ~= 0xFFFFFF then
            gpu.setForeground(0xFFFFFF)
        end
        

        biggest_name = math.max(biggest_name, unicode.len(name))
        local pad = string.rep(" ", biggest_name - unicode.len(name) + 1)
        prefix = string.format("%s%s", name, pad)

        gpu.set(1, line, prefix)
        gpu.setForeground(0xFFFFFF)

        suffix = string.format("%.2f%% (%d)", percentage * 100, quantity)
        biggest_suffix = math.max(biggest_suffix, unicode.len(suffix))
        pad = string.rep(" ", biggest_suffix - unicode.len(suffix))
        suffix = string.format("%s%s", pad, suffix)

        progress_bar = buildProgressBar(prefix, suffix, percentage, true)
        
        gpu.set(#prefix + 1, line, progress_bar)
        local width, height = gpu.getResolution()
        local suffixX = width - unicode.len(suffix) + 1
        gpu.set(suffixX, line, suffix)
        line = line + 1

        if quantity < MAX_QUANTITY then
            goto continue
        end
        rs_interface_0.extractItem(stack, 64, TRASH_SIDE)

        ::continue::
    end
end

os.execute("clear")