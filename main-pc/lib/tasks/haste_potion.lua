local M = {}

local GLASS_BOTTLE_SLOT = 7
local GLASS_BOTTLE_NAME = "minecraft:glass_bottle"

local NETHER_WART_SLOT = 8
local NETHER_WART_NAME = "minecraft:nether_wart"

local PRISMARINE_CRYSTALS_SLOT = 9
local PRISMARINE_CRYSTALS_NAME = "minecraft:prismarine_crystals"

local GLOWSTONE_DUST_SLOT = 10
local GLOWSTONE_DUST_NAME = "minecraft:glowstone_dust"

local function getStackName(stack)
  if type(stack) ~= "table" then return nil end
  return stack.name
end

local function getInventorySize(transposer, side)
  local size = transposer.getInventorySize(side)
  if type(size) ~= "number" then return 0 end
  return size
end

local function getStackInSlot(transposer, side, slot)
  local ok, stack = pcall(transposer.getStackInSlot, side, slot)
  if not ok then return nil end
  return stack
end

local function slotNeedsItem(ctx, slot, itemName)
  local transposer = ctx.potionTransposer
  if not transposer then return false end

  local brewerSide = ctx.config.POTION_BREWER_SIDE
  local stack = getStackInSlot(transposer, brewerSide, slot)

  if not stack then return true end
  if getStackName(stack) == itemName then return false end

  return false
end

local function findItemInBuffer(ctx, itemName)
  local transposer = ctx.potionTransposer
  if not transposer then return nil end

  local bufferSide = ctx.config.POTION_CHEST_SIDE_T
  local size = getInventorySize(transposer, bufferSide)

  for slot = 1, size do
    local stack = getStackInSlot(transposer, bufferSide, slot)
    if getStackName(stack) == itemName then
      return slot
    end
  end

  return nil
end

local function extractOneToBuffer(ctx, itemName)
  local rsPotion = ctx.rsPotion
  if not rsPotion then return false end

  local bufferSideFromRs = ctx.config.POTION_CHEST_SIDE_RS
  local moved = rsPotion.extractItem({ name = itemName }, 1, bufferSideFromRs) or 0

  return moved > 0
end

local function ensureItemInBuffer(ctx, itemName)
  local slot = findItemInBuffer(ctx, itemName)
  if slot then return slot end

  if not extractOneToBuffer(ctx, itemName) then
    return nil
  end

  return findItemInBuffer(ctx, itemName)
end

local function moveOneToBrewer(ctx, brewerSlot, itemName)
  local transposer = ctx.potionTransposer
  if not transposer then return false end

  local bufferSlot = ensureItemInBuffer(ctx, itemName)
  if not bufferSlot then return false end

  local moved = transposer.transferItem(
    ctx.config.POTION_CHEST_SIDE_T,
    ctx.config.POTION_BREWER_SIDE,
    1,
    bufferSlot,
    brewerSlot
  ) or 0

  return moved > 0
end

local function refillSlot(ctx, brewerSlot, itemName)
  if not slotNeedsItem(ctx, brewerSlot, itemName) then
    return true
  end

  return moveOneToBrewer(ctx, brewerSlot, itemName)
end

function M.refill(ctx)
  if not ctx then return false end
  if not ctx.potionTransposer then return false end
  if not ctx.rsPotion then return false end

  refillSlot(ctx, GLASS_BOTTLE_SLOT, GLASS_BOTTLE_NAME)
  refillSlot(ctx, NETHER_WART_SLOT, NETHER_WART_NAME)
  refillSlot(ctx, PRISMARINE_CRYSTALS_SLOT, PRISMARINE_CRYSTALS_NAME)
  refillSlot(ctx, GLOWSTONE_DUST_SLOT, GLOWSTONE_DUST_NAME)

  return true
end

return M
