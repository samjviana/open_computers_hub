local component = require("component")

local M = {}

function M.load(config)
  return {
    config = config,
    gpu = component.gpu,
    redstone = component.proxy(config.REDSTONE_IO),
    rsMain = component.proxy(config.RS_MAIN),
    rsAux = component.proxy(config.RS_AUX),
    rsPotion = component.proxy(config.RS_POTION),
    potion_transposer = component.proxy(config.POTION_TRANSPOSER),
  }
end

return M
