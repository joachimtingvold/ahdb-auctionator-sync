-- Sum quantities of buyout listings for the same item.
-- Run independently: lua5.1 tests/003_sum-buyout-quantity.lua
local addon_path = (arg[0]:match("^(.*)/") or ".") .. "/../AHDBAuctionatorSync.lua"

-- Arrange: provide only the WoW/addon interfaces needed by this case.
local env = setmetatable({}, {__index = _G})
env._G = env
env.print = function() end
env.UnitFactionGroup = function() return "Alliance" end
env.GetServerTime = function() return 1794758400 end
env.SlashCmdList = {}
local frame
function env.CreateFrame()
  frame = {RegisterEvent = function() end}
  function frame:SetScript(event, callback) self[event] = callback end
  return frame
end
local listener
local imports = {}
env.AuctionDB = {scanHouseName = "Alliance", scanStart = 101}
function env.AuctionDB:Listen(event, callback)
  assert(event == "SCAN_DATA", "Expected a completed-scan listener, got " .. tostring(event))
  listener = callback
end
function env.AuctionDB:LastPrice() error("Unexpected historical-price lookup") end
env.Auctionator = {Database = {db = {}}}
function env.Auctionator.Database:ProcessScan(data)
  imports[#imports + 1] = data
end

local addon = assert(loadfile(addon_path))
setfenv(addon, env)()
frame.OnEvent(frame, "ADDON_LOADED", "AHDBAuctionatorSync")
frame.OnEvent(frame, "PLAYER_LOGIN")

-- Act.
listener(env.AuctionDB, {n = 3, item = {10940, 10940, 10940}, count = {10, 5, 1}, buyout = {2100, 500, 0}})

-- Assert.
assert(#imports == 1, "Expected exactly one price import")
assert(imports[1]["10940"][1].available == 15, "Expected buyout quantity 15; bid-only quantity must be excluded")
print("PASS: 003_sum-buyout-quantity.lua")
