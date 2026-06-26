local component = require("component")

local M = {}

function M.load(config)
  return {
    config = config,
    gpu = component.gpu,
    redstone = component.proxy(config.REDSTONE_IO),
    rsMain = component.proxy(config.RS_MAIN),
    rsAux = component.proxy(config.RS_AUX)
  }
end

return M
