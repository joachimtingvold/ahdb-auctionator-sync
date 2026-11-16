-- A manual import uses the recent price stored by AHDB.
-- Run independently: lua5.1 tests/010_import-recent-history.lua
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
local now = env.GetServerTime()
local prices = {
  [10940] = {now - 30, 125, 150, 20},
  [10978] = {now - 86400 * 5, 500, 500, 2},
}
function env.AuctionDB:SavedHouse(house)
  assert(house == "Alliance", "History must be read from the character's faction")
  return {items = {[10940] = true, [10978] = true}, daily = {}}
end
function env.AuctionDB:LastPrice(id) return prices[id] end

local addon = assert(loadfile(addon_path))
setfenv(addon, env)()
frame.OnEvent(frame, "ADDON_LOADED", "AHDBAuctionatorSync")
frame.OnEvent(frame, "PLAYER_LOGIN")

-- Act.
env.SlashCmdList.AHDBAUCTIONATORSYNC("import")

-- Assert.
assert(#imports == 1, "Expected one manual import")
assert(imports[1]["10940"][1].price == 125, "Expected recent historical price of 125 copper")
print("PASS: 010_import-recent-history.lua")
