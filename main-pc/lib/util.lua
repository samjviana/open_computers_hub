local unicode = require("unicode")

local M = {}

function M.ulen(value)
  return unicode.len(value or "")
end

function M.startsWith(str, prefix)
  return string.sub(str or "", 1, #prefix) == prefix
end

function M.padRight(str, width)
  str = str or ""
  local len = M.ulen(str)
  if len >= width then return str end
  return str .. string.rep(" ", width - len)
end

function M.padLeft(str, width)
  str = str or ""
  local len = M.ulen(str)
  if len >= width then return str end
  return string.rep(" ", width - len) .. str
end

return M
