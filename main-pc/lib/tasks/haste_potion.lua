local M = {}

local GLASS_BOTTLE_SLOT = 7
local GLASS_BOTTLE_NAME = "minecraft:glass_bottle"
local NETHER_WART_SLOT = 8
local NETHER_WART_NAME = "minecraft:nether_wart"
local PRISMARINE_CRYSTALS_SLOT = 9
local PRISMARINE_CRYSTALS_NAME = "minecraft:prismarine_crystals"
local GLOWSTONE_DUST_SLOT = 10
local GLOWSTONE_DUST_NAME = "minecraft:glowstone_dust"

local function needItem(ctx, item_slot)
  local rs_potion = ctx.rsPotion
  if not rs_potion then return false end

  local potionChestSide = ctx.config.POTION_CHEST_SIDE

  local count = rs_potion.getSlotStackSize(potionChestSide, item_slot) or 0
  if count > 0 then return false end
end

local function findItem(ctx, item_name)
  local rs_potion = ctx.rsPotion
  if not rs_potion then return nil end

  local potionChestSide = ctx.config.POTION_CHEST_SIDE

  local size = rs_potion.getInventorySize(potionChestSide) or 0
  for slot = 1, size do
    local stack = rs_potion.getSlotStack(potionChestSide, slot)
    if type(stack) == "table" and stack.name == item_name then
      return slot
    end
  end

  return nil
end

local function moveItem(ctx, itemSlot, itemName)
  local transposer = ctx.potionTransposer
  if not transposer then return false end

  local rs_potion = ctx.rsPotion
  if not rs_potion then return false end

  local potionBrewerSide = ctx.config.POTION_BREWER_SIDE
  local potionChestSide = ctx.config.POTION_CHEST_SIDE

  local moved = rs_potion.extractItem({name = itemName}, 1, potionChestSide)
  if not moved then return false end

  local bufferSlot = findItem(ctx, itemName)
  if not bufferSlot then return false end

  local success = transposer.transferItem(potionChestSide, potionBrewerSide, 1, bufferSlot, itemSlot)

  if not success then return false end
end

function M.refill(ctx)
  local transposer = ctx.potionTransposer
  if not transposer then return false end

  local rs_potion = ctx.rsPotion
  if not rs_potion then return false end

  if needItem(ctx, GLASS_BOTTLE_SLOT) then
    local moved = moveItem(ctx, GLASS_BOTTLE_SLOT, GLASS_BOTTLE_NAME)
    if not moved then return false end
  end

  if needItem(ctx, NETHER_WART_SLOT) then
    local moved = moveItem(ctx, NETHER_WART_SLOT, NETHER_WART_NAME)
    if not moved then return false end
  end

  if needItem(ctx, PRISMARINE_CRYSTALS_SLOT) then
    local moved = moveItem(ctx, PRISMARINE_CRYSTALS_SLOT, PRISMARINE_CRYSTALS_NAME)
    if not moved then return false end
  end

  if needItem(ctx, GLOWSTONE_DUST_SLOT) then
    local moved = moveItem(ctx, GLOWSTONE_DUST_SLOT, GLOWSTONE_DUST_NAME)
    if not moved then return false end
  end


end

return M