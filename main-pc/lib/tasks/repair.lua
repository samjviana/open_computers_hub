local M = {}

local function containsPlain(str, needle)
  return string.find(str or "", needle, 1, true) ~= nil
end

function M.shouldExtract(ctx, stack)
  if type(stack) ~= "table" then return false end

  local itemId = stack.name or ""
  local damage = stack.damage or 0
  local maxDamage = stack.maxDamage or 0

  if damage <= 0 or maxDamage <= 0 then return false end

  local blocklist = ctx.config.DAMAGED_BLOCKLIST
  for i = 1, #blocklist do
    if containsPlain(itemId, blocklist[i]) then
      return false
    end
  end

  return true
end

function M.extract(ctx, stack)
  local quantity = stack.size or 0
  if quantity <= 0 then return false end
  return ctx.rsMain.extractItem(stack, quantity, ctx.config.CHEST_SIDE)
end

return M
