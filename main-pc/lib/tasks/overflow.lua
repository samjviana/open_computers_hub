local M = {}

function M.processStack(ctx, stack)
  local quantity = stack.size or 0
  if quantity < ctx.config.MAX_QUANTITY then return false end
  return ctx.rsMain.extractItem(stack, 64, ctx.config.TRASH_SIDE)
end

return M
