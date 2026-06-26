local shell = require("shell")
local fs = require("filesystem")

local BASE_URL = "https://raw.githubusercontent.com/samjviana/open_computers_hub/refs/heads/main/main-pc"
local ROOT_DIR = "/home"
local MANIFEST_PATH = "/home/manifest.lua"

local function getParentDir(path)
  return path:match("^(.*)/[^/]+$")
end

local function ensureDir(path)
  local current = ""

  for part in path:gmatch("[^/]+") do
    current = current .. "/" .. part

    if not fs.exists(current) then
      fs.makeDirectory(current)
    end
  end
end

local function downloadFile(file)
  local url = BASE_URL .. "/" .. file
  local target = ROOT_DIR .. "/" .. file
  local parentDir = getParentDir(target)

  if parentDir then
    ensureDir(parentDir)
  end

  print("Downloading " .. file)
  shell.execute("wget", nil, "-f", url, target)
end

print("Downloading manifest")
shell.execute("wget", nil, "-f", BASE_URL .. "/manifest.lua", MANIFEST_PATH)

local files = dofile(MANIFEST_PATH)

for _, file in ipairs(files) do
  downloadFile(file)
end

fs.remove(MANIFEST_PATH)

print("Done")