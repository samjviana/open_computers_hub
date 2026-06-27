local ITEMS = {
  { slot = 7, name = "minecraft:glass_bottle" },
  { slot = 8, name = "minecraft:nether_wart" },
  { slot = 9, name = "minecraft:prismarine_crystals" },
  { slot = 10, name = "minecraft:glowstone_dust" }
}

local function getStack(ctx, side, slot)
  local ok, stack = pcall(ctx.potionTransposer.getStackInSlot, side, slot)
  if not ok then return nil end
  return stack
end

local function slotNeedsItem(ctx, slot, itemName)
  local stack = getStack(ctx, ctx.config.POTION_BREWER_SIDE, slot)

  if not stack then return true end
  if stack.name ~= itemName then return false end
  if (stack.size or 0) <= 0 then return true end

  return false
end

local function findItemInBuffer(ctx, itemName)
  local transposer = ctx.potionTransposer
  local bufferSide = ctx.config.POTION_CHEST_SIDE_T
  local size = transposer.getInventorySize(bufferSide) or 0

  for slot = 1, size do
    local stack = getStack(ctx, bufferSide, slot)

    if stack and stack.name == itemName and (stack.size or 0) > 0 then
      return slot
    end
  end

  return nil
end

local function extractOneToBuffer(ctx, itemName)
  local moved = ctx.rsPotion.extractItem(
    { name = itemName },
    1,
    ctx.config.POTION_CHEST_SIDE_RS
  ) or 0

  return moved > 0
end

local function moveOneToBrewer(ctx, item)
  local bufferSlot = findItemInBuffer(ctx, item.name)

  if not bufferSlot then
    if not extractOneToBuffer(ctx, item.name) then
      return false
    end

    bufferSlot = findItemInBuffer(ctx, item.name)
    if not bufferSlot then
      return false
    end
  end

  local moved = ctx.potionTransposer.transferItem(
    ctx.config.POTION_CHEST_SIDE_T,
    ctx.config.POTION_BREWER_SIDE,
    1,
    bufferSlot,
    item.slot
  ) or 0

  return moved > 0
end

function M.refill(ctx)
  if not ctx then return false end
  if not ctx.potionTransposer then return false end
  if not ctx.rsPotion then return false end

  local movedAny = false

  for _, item in ipairs(ITEMS) do
    if slotNeedsItem(ctx, item.slot, item.name) then
      local moved = moveOneToBrewer(ctx, item)

      if moved then
        movedAny = true
      end
    end
  end

  return movedAny
end