local util = require("util")

local M = {}

local WHITE = 0xFFFFFF
local YELLOW = 0xFFFF55
local YELLOW_PREFIX = "\u{00A7}e"

local screenW = 80
local screenH = 25
local fg = WHITE
local lastRenderedRows = 0

local function setFg(ctx, color)
  if fg ~= color then
    ctx.gpu.setForeground(color)
    fg = color
  end
end

local function progressBar(width, progress)
  if width < 1 then width = 1 end
  if progress < 0 then progress = 0 end
  if progress > 1 then progress = 1 end

  local filled = math.floor(progress * width)
  return string.rep("█", filled) .. string.rep("░", width - filled)
end

local function clearLine(ctx, y)
  ctx.gpu.fill(1, y, screenW, 1, " ")
end

local function stripYellowPrefix(name)
  if util.startsWith(name, YELLOW_PREFIX) then
    return string.sub(name, #YELLOW_PREFIX + 1), true
  end
  return name, false
end

local function progressLine(prefix, suffix, progress)
  local barW = screenW - util.ulen(prefix) - util.ulen(suffix) - 2
  return prefix .. " " .. progressBar(barW, progress) .. " " .. suffix
end

function M.init(ctx)
  os.execute("clear")
  local maxWidth, maxHeight = ctx.gpu.maxResolution()
  ctx.gpu.setResolution(math.min(160, maxWidth), math.min(50, maxHeight))
  screenW, screenH = ctx.gpu.getResolution()
  fg = WHITE
  lastRenderedRows = 0
end

function M.cleanup(ctx)
  setFg(ctx, WHITE)
  os.execute("clear")
end

function M.acceptStack(ctx, stack)
  return (stack.size or 0) >= ctx.config.DISPLAY_THRESHOLD
end

function M.renderStorage(ctx)
  local storages = ctx.rsMain.getStorages()
  if type(storages) ~= "table" or not storages.total or not storages.total.item then
    clearLine(ctx, 1)
    setFg(ctx, WHITE)
    ctx.gpu.set(1, 1, "Storage Monitor - RS indisponivel")
    return
  end

  local storage = storages.total.item
  local capacity = storage.capacity or 0
  local usage = storage.usage or 0
  local percentage = capacity > 0 and (usage / capacity) or 0
  local suffix = string.format("%.2f%% (%d / %d)", percentage * 100, usage, capacity)

  clearLine(ctx, 1)
  setFg(ctx, WHITE)
  ctx.gpu.set(1, 1, progressLine("Storage Monitor", suffix, percentage))
end

local function sortBySizeDesc(a, b)
  return (a.size or 0) > (b.size or 0)
end

function M.renderItems(ctx, displayItems)
  table.sort(displayItems, sortBySizeDesc)

  local maxRows = math.max(0, screenH - 2)
  local count = math.min(#displayItems, maxRows)
  local rows = {}
  local nameW = 0
  local suffixW = 0

  for i = 1, count do
    local stack = displayItems[i]
    local itemId = stack.name or ""
    local rawName = stack.label or itemId
    local name, yellow = stripYellowPrefix(rawName)
    local quantity = stack.size or 0
    local percentage = quantity / ctx.config.MAX_QUANTITY
    local suffix = string.format("%.2f%% (%d)", percentage * 100, quantity)

    nameW = math.max(nameW, util.ulen(name))
    suffixW = math.max(suffixW, util.ulen(suffix))

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
    local prefix = util.padRight(row.name, nameW + 1)
    local suffix = util.padLeft(row.suffix, suffixW)
    local barW = screenW - util.ulen(prefix) - util.ulen(suffix)
    local bar = progressBar(barW, row.percentage)

    clearLine(ctx, y)
    if row.yellow then
      setFg(ctx, YELLOW)
      ctx.gpu.set(1, y, prefix)
      setFg(ctx, WHITE)
      ctx.gpu.set(util.ulen(prefix) + 1, y, bar .. suffix)
    else
      setFg(ctx, WHITE)
      ctx.gpu.set(1, y, prefix .. bar .. suffix)
    end
  end

  for y = count + 3, lastRenderedRows + 2 do
    clearLine(ctx, y)
  end
  lastRenderedRows = count
end

return M
