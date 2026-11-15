-- Run from repository root: lua5.1 tests/test_sync.lua
local messages = {}
_G.print = function(s) messages[#messages + 1] = tostring(s) end
_G.UnitFactionGroup = function(unit) return unit == 'player' and 'Alliance' or nil end
local now = 1794758400
_G.GetServerTime = function() return now end
_G.CreateFrame = function()
  local frame = {}
  function frame:RegisterEvent(event) end
  function frame:SetScript(event, callback) self[event] = callback end
  _G.mockFrame = frame
  return frame
end
_G.SlashCmdList = {}
local invoked = 0
local lastData
_G.Auctionator = {Database = {db={}}}
function Auctionator.Database:ProcessScan(data)
  invoked = invoked + 1
  lastData = data
  for key, prices in pairs(data) do
    local record = self.db[key] or {m=0}
    -- Mock mimics Auctionator preserving a lower daily low;
    -- addon should correct .m to current scan minimum.
    record.m = math.min(record.m > 0 and record.m or math.huge, prices[1].price)
    self.db[key] = record
  end
  return invoked
end
local events = {}
local historical = { [10940] = {now - 30, 125, 150, 20}, [10978] = {now - 86400 * 5, 500, 500, 2}}
_G.AuctionDB = {scanHouseName = 'Alliance', scanStart = 101, saved = {items={[10940]='x',[10978]='x'},daily={}}}
function AuctionDB:Listen(name, cb) events[name] = cb end
function AuctionDB:LastPrice(id, house) return historical[id] end
function AuctionDB:SavedHouse(house) return house=='Alliance' and self.saved or nil end
local addon = 'AHDBAuctionatorSync'
dofile('AHDBAuctionatorSync.lua')
mockFrame.OnEvent(mockFrame,'ADDON_LOADED',addon)
mockFrame.OnEvent(mockFrame,'PLAYER_LOGIN')
assert(events.SCAN_DATA,'listener must register')

local scanned = {n=4,
  item = {10940, 10940, 10940, 1234},
  count = {10, 5, 1, 2},
  buyout = {2100, 500, 0, 0},
}
events.SCAN_DATA(AuctionDB, scanned)
assert(invoked==1,'process scan once')
assert(lastData['10940'][1].price==100,'min unit price')
assert(lastData['10940'][1].available==15,'sum buyout quantity')
assert(Auctionator.Database.db['10940'].m==100,'saved .m price')
assert(lastData['1234']==nil,'bid-only no price')
events.SCAN_DATA(AuctionDB, scanned)
assert(invoked==1,'duplicate scan should be ignored')
AuctionDB.scanHouseName = 'Neutral'
AuctionDB.scanStart = 102
events.SCAN_DATA(AuctionDB, scanned)
assert(invoked==1,'neutral must not contaminate faction')
AuctionDB.scanHouseName = 'Alliance'
AuctionDB.scanStart = 103
scanned.buyout = {3000, 1000, 0, 0} -- min 200; higher than the old min 100
events.SCAN_DATA(AuctionDB, scanned)
assert(invoked==2)
assert(Auctionator.Database.db['10940'].m==200,'latest scan must update even when higher')
SlashCmdList.AHDBAUCTIONATORSYNC('off')
AuctionDB.scanStart = 104
events.SCAN_DATA(AuctionDB, scanned)
assert(invoked==2,'disabled automatic update')
SlashCmdList.AHDBAUCTIONATORSYNC('import')
assert(invoked==3,'manual import allowed while disabled')
assert(Auctionator.Database.db['10940'].m==125,'manual import current price')
assert(Auctionator.Database.db['10978']==nil,'old history excluded by default')
SlashCmdList.AHDBAUCTIONATORSYNC('age 0')
SlashCmdList.AHDBAUCTIONATORSYNC('import')
assert(Auctionator.Database.db['10978'].m==500,'unlimited age backfill')
SlashCmdList.AHDBAUCTIONATORSYNC('on')
assert(AHDBAuctionatorSyncDB.enabled == true)
assert(AHDBAuctionatorSyncDB.lastImport.items==2)
io.write('PASS: scan aggregation, persisted prices, duplicate suppression, neutral isolation, enable/disable, historical backfill\n')
