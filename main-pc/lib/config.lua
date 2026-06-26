local sides = require("sides")

local config = {
  REDSTONE_IO = "8ce8192e-61c3-4da7-b4cf-3f6f0e47e27e",
  RS_MAIN = "015f8bd9-e59e-41e5-9673-044f5cd34150",
  RS_AUX = "e2ebf32c-a6b3-47c2-9a54-bc3d3975b4e5",

  STOP_SIDE = sides.south,
  TRASH_SIDE = sides.south,
  CHEST_SIDE = sides.north,
  WHEAT_CHEST_SIDE = sides.south,

  MAX_QUANTITY = 20000,
  DISPLAY_RATIO = 0.4,

  COW_COUNT = 15,
  COW_FEED_COOLDOWN = 600,

  ITEM_SCAN_INTERVAL = 0.50,
  DISPLAY_INTERVAL = 1.00,
  STORAGE_INTERVAL = 5.00,
  WHEAT_RETRY_INTERVAL = 5.00,

  -- Segurança: mesmo se nenhum job estiver perto, acorda ocasionalmente.
  MAX_EVENT_WAIT = 1.00,
  MIN_EVENT_WAIT = 0.01,

  DAMAGED_BLOCKLIST = {
    "tconstruct",
    "plustic",
    "canister",
    "oxygen_tank",
    "infusion_crystal"
  }
}

config.DISPLAY_THRESHOLD = config.MAX_QUANTITY * config.DISPLAY_RATIO

return config
