-- Regression: a higher new price replaces the earlier current price.
-- Run independently: lua5.1 tests/013_update-current-price-when-it-increases.lua
local addon_path = (arg[0]:match("^(.*)/") or ".") .. "/../AuctionSync.lua"

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
env.Auctionator.Database.db["10940"] = {m = 100}
-- Auctionator can retain a lower daily minimum during ProcessScan.
-- Leave that record unchanged so the addon must update its current-price field.

local addon = assert(loadfile(addon_path))
setfenv(addon, env)()
frame.OnEvent(frame, "ADDON_LOADED", "AuctionSync")
frame.OnEvent(frame, "PLAYER_LOGIN")

-- Act.
listener(env.AuctionDB, {n = 1, item = {10940}, count = {2}, buyout = {200}})
env.AuctionDB.scanStart = 102
listener(env.AuctionDB, {n = 1, item = {10940}, count = {2}, buyout = {400}})

-- Assert.
assert(#imports == 2, "Expected both distinct scans to be imported")
assert(env.Auctionator.Database.db["10940"].m == 200, "Current price remained at the old daily low instead of rising to 200 copper")
print("PASS: 013_update-current-price-when-it-increases.lua")
