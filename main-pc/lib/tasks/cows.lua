local M = {}

local lastCowFeed = -math.huge
local lastWheatTry = -math.huge

local function findItem(items, itemName)
  for i = 1, #items do
    local stack = items[i]
    if type(stack) == "table" and stack.name == itemName then
      return stack
    end
  end
  return nil
end

function M.tick(ctx, items, now)
  local cfg = ctx.config

  if now - lastCowFeed < cfg.COW_FEED_COOLDOWN then return false end
  if now - lastWheatTry < cfg.WHEAT_RETRY_INTERVAL then return false end
  lastWheatTry = now

  local wheat = findItem(items, "minecraft:wheat")
  if not wheat then return false end

  local moved = ctx.rsAux.extractItem(wheat, cfg.COW_COUNT, cfg.WHEAT_CHEST_SIDE)
  if moved then
    lastCowFeed = now
    return true
  end

  return false
end

return M
