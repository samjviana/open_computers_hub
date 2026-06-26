local component = require("component")
local computer = require("computer")
local sides = require("sides")
local unicode = require("unicode")
local gpu = component.gpu

local redstone_io = component.proxy("8ce8192e-61c3-4da7-b4cf-3f6f0e47e27e")
local rs_interface_0 = component.proxy("015f8bd9-e59e-41e5-9673-044f5cd34150")
local rs_interface_1 = component.proxy("e2ebf32c-a6b3-47c2-9a54-bc3d3975b4e5")

local STOP_SIDE = sides.south
local TRASH_SIDE = sides.south
local CHEST_SIDE = sides.north
local WHEAT_CHEST_SIDE = sides.south

local MAX_QUANTITY = 20000
local DISPLAY_THRESHOLD = MAX_QUANTITY * 0.4
local COW_COUNT = 15
local COW_FEED_COOLDOWN = 600 -- 10 minutes

local LOOP_SLEEP = 0.05
local ITEM_SCAN_INTERVAL = 0.50    -- chama getItems() no maximo 2x/s.
local DISPLAY_INTERVAL = 1.00      -- redesenha a tela no maximo 1x/s.
local STORAGE_INTERVAL = 5.00      -- getStorages() e bem menos urgente.
local WHEAT_RETRY_INTERVAL = 5.00  -- se nao houver trigo, nao fica varrendo isso todo tick.

local WHITE = 0xFFFFFF
local YELLOW = 0xFFFF55
local YELLOW_PREFIX = "\u{00A7}e"

os.execute("clear")
local maxWidth, maxHeight = gpu.maxResolution()
gpu.setResolution(math.min(160, maxWidth), math.min(50, maxHeight))
local screenW, screenH = gpu.getResolution()

local fg = WHITE
local function setFg(color)
  if fg ~= color then
    gpu.setForeground(color)
    fg = color
  end
end

local function ulen(s)
  return unicode.len(s or "")
end

local function padRight(s, width)
  local len = ulen(s)
  if len >= width then return s end
  return s .. string.rep(" ", width - len)
end

local function padLeft(s, width)
  local len = ulen(s)
  if len >= width then return s end
  return string.rep(" ", width - len) .. s
end

local function startsWith(str, prefix)
  return string.sub(str, 1, #prefix) == prefix
end

local function stripYellowPrefix(name)
  if startsWith(name, YELLOW_PREFIX) then
    return string.sub(name, #YELLOW_PREFIX + 1), true
  end
  return name, false
end

local function progressBar(width, progress)
  if width < 1 then width = 1 end
  if progress < 0 then progress = 0 end
  if progress > 1 then progress = 1 end
  local filled = math.floor(progress * width)
  return string.rep("█", filled) .. string.rep("░", width - filled)
end

local function progressLine(prefix, suffix, progress)
  local barW = screenW - ulen(prefix) - ulen(suffix) - 2
  return prefix .. " " .. progressBar(barW, progress) .. " " .. suffix
end

local function clearLine(y)
  gpu.fill(1, y, screenW, 1, " ")
end

local damagedBlocklist = {
  "tconstruct",
  "plustic",
  "canister",
  "oxygen_tank",
  "infusion_crystal"
}

local function shouldExtractDamaged(item_id)
  for i = 1, #damagedBlocklist do
    if string.find(item_id, damagedBlocklist[i], 1, true) then
      return false
    end
  end
  return true
end

local function findItemInList(items, item_id)
  for i = 1, #items do
    local stack = items[i]
    if type(stack) == "table" and stack.name == item_id then
      return stack
    end
  end
  return nil
end

local lastCowFeed = -COW_FEED_COOLDOWN
local lastWheatTry = -WHEAT_RETRY_INTERVAL
local function feedCows(items, now)
  if now - lastCowFeed < COW_FEED_COOLDOWN then return end
  if now - lastWheatTry < WHEAT_RETRY_INTERVAL then return end
  lastWheatTry = now

  local wheat = findItemInList(items, "minecraft:wheat")
  if not wheat then return end

  local moved = rs_interface_1.extractItem(wheat, COW_COUNT, WHEAT_CHEST_SIDE)
  if moved then
    lastCowFeed = now
  end
end

local function scanItems(items, now)
  local display = {}

  for i = 1, #items do
    local stack = items[i]
    if type(stack) == "table" then
      local item_id = stack.name or ""
      local quantity = stack.size or 0
      local damage = stack.damage or 0
      local maxDamage = stack.maxDamage or 0

      if damage > 0 and maxDamage > 0 and shouldExtractDamaged(item_id) then
        rs_interface_0.extractItem(stack, quantity, CHEST_SIDE)
      else
        if quantity >= DISPLAY_THRESHOLD then
          display[#display + 1] = stack
        end

        if quantity >= MAX_QUANTITY then
          rs_interface_0.extractItem(stack, 64, TRASH_SIDE)
        end
      end
    end
  end

  feedCows(items, now)
  return display
end

local sortBySizeDesc = function(a, b)
  return (a.size or 0) > (b.size or 0)
end

local function renderStorage()
  local storages = rs_interface_0.getStorages()
  if type(storages) ~= "table" or not storages.total or not storages.total.item then
    clearLine(1)
    setFg(WHITE)
    gpu.set(1, 1, "Storage Monitor - RS indisponivel")
    return
  end

  local storage = storages.total.item
  local capacity = storage.capacity or 0
  local usage = storage.usage or 0
  local percentage = capacity > 0 and (usage / capacity) or 0
  local suffix = string.format("%.2f%% (%d / %d)", percentage * 100, usage, capacity)

  clearLine(1)
  setFg(WHITE)
  gpu.set(1, 1, progressLine("Storage Monitor", suffix, percentage))
end

local lastRenderedRows = 0
local function renderItems(display)
  table.sort(display, sortBySizeDesc)

  local maxRows = math.max(0, screenH - 2)
  local count = math.min(#display, maxRows)
  local rows = {}
  local nameW = 0
  local suffixW = 0

  for i = 1, count do
    local stack = display[i]
    local item_id = stack.name or ""
    local rawName = stack.label or item_id
    local name, yellow = stripYellowPrefix(rawName)
    local quantity = stack.size or 0
    local percentage = quantity / MAX_QUANTITY
    local suffix = string.format("%.2f%% (%d)", percentage * 100, quantity)

    local nameLen = ulen(name)
    local suffixLen = ulen(suffix)
    if nameLen > nameW then nameW = nameLen end
    if suffixLen > suffixW then suffixW = suffixLen end

    rows[i] = {
      name = name,
      yellow = yellow,
      suffix = suffix,
      percentage = percentage
    }
  end

  for i = 1, count do
    local y = i + 2
    local row = rows[i]
    local prefix = padRight(row.name, nameW + 1)
    local suffix = padLeft(row.suffix, suffixW)
    local barW = screenW - ulen(prefix) - ulen(suffix)
    local bar = progressBar(barW, row.percentage)

    clearLine(y)
    if row.yellow then
      setFg(YELLOW)
      gpu.set(1, y, prefix)
      setFg(WHITE)
      gpu.set(ulen(prefix) + 1, y, bar .. suffix)
    else
      setFg(WHITE)
      gpu.set(1, y, prefix .. bar .. suffix)
    end
  end

  for y = count + 3, lastRenderedRows + 2 do
    clearLine(y)
  end
  lastRenderedRows = count
end

local lastItemScan = -ITEM_SCAN_INTERVAL
local lastDisplay = -DISPLAY_INTERVAL
local lastStorage = -STORAGE_INTERVAL
local displayCache = {}

while redstone_io.getInput(STOP_SIDE) == 0 do
  local now = computer.uptime()

  if now - lastStorage >= STORAGE_INTERVAL then
    renderStorage()
    lastStorage = now
  end

  if now - lastItemScan >= ITEM_SCAN_INTERVAL then
    local items = rs_interface_0.getItems()
    if type(items) == "table" then
      displayCache = scanItems(items, now)
    else
      displayCache = {}
    end
    lastItemScan = now
  end

  if now - lastDisplay >= DISPLAY_INTERVAL then
    renderItems(displayCache)
    lastDisplay = now
  end

  os.sleep(LOOP_SLEEP)
end

os.execute("clear")
