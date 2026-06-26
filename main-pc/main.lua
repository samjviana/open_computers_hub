local computer = require("computer")
local event = require("event")

local config = require("config")
local components = require("components")
local display = require("ui.storage_display")
local cows = require("tasks.cows")
local repair = require("tasks.repair")
local overflow = require("tasks.overflow")

local ctx = components.load(config)

display.init(ctx)

local displayCache = {}

local lastStorage = -config.STORAGE_INTERVAL
local lastItemScan = -config.ITEM_SCAN_INTERVAL
local lastDisplay = -config.DISPLAY_INTERVAL

local function isStopPressed()
  return ctx.redstone.getInput(config.STOP_SIDE) > 0
end

local function shouldStopFromSignal(name, address, side, oldValue, newValue)
  if name == "interrupted" then
    return true
  end

  if name == "redstone_changed"
      and address == config.REDSTONE_IO
      and side == config.STOP_SIDE
      and (newValue or 0) > 0 then
    return true
  end

  return false
end

local function due(now, lastRun, interval)
  return now - lastRun >= interval
end

local function nextWait(now)
  local nextStorage = lastStorage + config.STORAGE_INTERVAL
  local nextItemScan = lastItemScan + config.ITEM_SCAN_INTERVAL
  local nextDisplay = lastDisplay + config.DISPLAY_INTERVAL
  local nextRun = math.min(nextStorage, nextItemScan, nextDisplay)

  local wait = nextRun - now
  if wait < config.MIN_EVENT_WAIT then return config.MIN_EVENT_WAIT end
  if wait > config.MAX_EVENT_WAIT then return config.MAX_EVENT_WAIT end
  return wait
end

local function scanItems(now)
  local items = ctx.rsMain.getItems()
  displayCache = {}

  if type(items) ~= "table" then
    return
  end

  for i = 1, #items do
    local stack = items[i]
    if type(stack) == "table" then
      if repair.shouldExtract(ctx, stack) then
        repair.extract(ctx, stack)
      else
        overflow.processStack(ctx, stack)

        if display.acceptStack(ctx, stack) then
          displayCache[#displayCache + 1] = stack
        end
      end
    end
  end

  cows.tick(ctx, items, now)
end

while not isStopPressed() do
  local now = computer.uptime()

  if due(now, lastStorage, config.STORAGE_INTERVAL) then
    display.renderStorage(ctx)
    lastStorage = now
  end

  if due(now, lastItemScan, config.ITEM_SCAN_INTERVAL) then
    scanItems(now)
    lastItemScan = now
  end

  if due(now, lastDisplay, config.DISPLAY_INTERVAL) then
    display.renderItems(ctx, displayCache)
    lastDisplay = now
  end

  local name, address, side, oldValue, newValue = event.pull(nextWait(computer.uptime()))
  if shouldStopFromSignal(name, address, side, oldValue, newValue) then
    break
  end
end

display.cleanup(ctx)
