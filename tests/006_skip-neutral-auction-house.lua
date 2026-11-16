-- A neutral scan cannot overwrite the faction price database.
-- Run independently: lua5.1 tests/006_skip-neutral-auction-house.lua
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
env.AuctionDB.scanHouseName = "Neutral"

local addon = assert(loadfile(addon_path))
setfenv(addon, env)()
frame.OnEvent(frame, "ADDON_LOADED", "AHDBAuctionatorSync")
frame.OnEvent(frame, "PLAYER_LOGIN")

-- Act.
listener(env.AuctionDB, {n = 1, item = {10940}, count = {2}, buyout = {200}})

-- Assert.
assert(#imports == 0, "Neutral auction-house prices were imported into the faction database")
print("PASS: 006_skip-neutral-auction-house.lua")
