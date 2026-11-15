-- AHDB Auctionator Sync: import AHDB faction scan prices into Auctionator.
-- Target client: World of Warcraft: Forever (Interface 16001).
-- AHDB SCAN_DATA is a completed-scan callback. No auction-house queries are made.
-- AHDB identifies items by base item ID, so randomized-item variants are not
-- individually priced. See README.md for limitations and usage.

local ADDON = "AHDBAuctionatorSync"
local TAG = "|cff77ccffAHDB Auctionator Sync|r: "
local defaults = { enabled = true, importMaxAgeHours = 48 }
local settings
local installed = false
local lastScanSignature

local function say(message)
  print(TAG .. tostring(message))
end

local function initSaved()
  AHDBAuctionatorSyncDB = AHDBAuctionatorSyncDB or {}
  settings = AHDBAuctionatorSyncDB
  for key, default in pairs(defaults) do
    if settings[key] == nil then settings[key] = default end
  end
end

local function dependencies()
  local adb = _G.AuctionDB
  local atr = _G.Auctionator
  if not (adb and type(adb.Listen) == "function" and type(adb.LastPrice) == "function") then
    return nil, nil, "AHDB 2.7.x unavailable or incompatible"
  end
  if not (atr and atr.Database and type(atr.Database.ProcessScan) == "function") then
    return nil, nil, "Auctionator.Database:ProcessScan unavailable or incompatible"
  end
  return adb, atr
end

local function market()
  return UnitFactionGroup("player") or "Neutral"
end

local function addPrice(index, id, price, quantity)
  id, price, quantity = tonumber(id), tonumber(price), tonumber(quantity)
  if not (id and id > 0 and price and price > 0 and quantity and quantity > 0) then
    return
  end
  -- Auctionator's BasicDBKeyFromLink returns the item ID as a *string*.
  local key = tostring(math.floor(id))
  local entry = index[key]
  if not entry then
    index[key] = {price = price, available = quantity}
  else
    if price < entry.price then entry.price = price end
    entry.available = entry.available + quantity
  end
end

local function fromScan(e)
  local index = {}
  if type(e) ~= "table" or type(e.item) ~= "table" or
      type(e.count) ~= "table" or type(e.buyout) ~= "table" or
      type(e.n) ~= "number" then
    return nil, "unexpected AHDB SCAN_DATA format"
  end

  for i = 1, e.n do
    local qty, buyout = tonumber(e.count[i]), tonumber(e.buyout[i])
    if qty and qty > 0 and buyout and buyout > 0 then
      -- AHDB uses floored copper-per-unit in its history (Scan.lua).
      addPrice(index, e.item[i], math.floor(buyout / qty), qty)
    end
  end
  return index
end

local function importPrices(index, sourceHouse, sourceDescription)
  local _, atr, err = dependencies()
  if not atr then return false, err end
  if sourceHouse ~= market() then
    return false, "Skipped " .. tostring(sourceHouse) .. " prices: Auctionator's active database is for " .. market()
  end

  local data = {}
  local expected = {}
  local count = 0
  for key, item in pairs(index) do
    local price = tonumber(item.price)
    local available = tonumber(item.available)
    if price and price > 0 and available and available > 0 then
      -- This is the SAME input structure used by Auctionator's own full scan.
      data[key] = {{price = price, available = available}}
      expected[key] = price
      count = count + 1
    end
  end
  if count == 0 then return false, "No buyout prices to import" end

  local ok, result = pcall(atr.Database.ProcessScan, atr.Database, data)
  if not ok then return false, "Auctionator rejected the scan: " .. tostring(result) end

  -- Correct the last-seen minimum to this completed AHDB scan when Auctionator
  -- exposes the .m field. ProcessScan maintains its regular daily history.
  local verified = 0
  if type(atr.Database.db) == "table" then
    for key, price in pairs(expected) do
      local entry = atr.Database.db[key]
      if type(entry) == "table" and type(entry.m) == "number" then
        entry.m = price
        verified = verified + 1
      end
    end
  end

  settings.lastImport = {
    timestamp = GetServerTime(),
    house = sourceHouse,
    items = count,
    via = sourceDescription,
    verified = verified,
  }
  return true, string.format("Updated %d Auctionator item prices (%d current-price records checked) from %s.",
    count, verified, sourceDescription)
end

local function onScan(adb, e)
  if not settings or not settings.enabled then return end
  local house = adb.scanHouseName
  if house ~= market() then
    -- AHDB maintains separate Alliance / Horde / Neutral markets. Auctionator
    -- has one active DB for this character, so never poison its faction prices
    -- with neutral AH (Gadgetzan, Booty Bay, Everlook) prices.
    say("AHDB " .. tostring(house) .. " scan completed; not imported into " .. market() .. " Auctionator prices.")
    return
  end
  local signature = tostring(adb.scanStart) .. ":" .. tostring(e and e.n) .. ":" .. tostring(house)
  if signature == lastScanSignature then return end

  local index, err = fromScan(e)
  if not index then say(err) return end
  local ok, message = importPrices(index, house, "AHDB full scan")
  if not ok then
    say("Import failed: " .. message)
  else
    lastScanSignature = signature
    say(message)
  end
end

-- Backfill without requesting any auction-house scan: useful after a fresh
-- installation when AHDB already scanned but Auctionator never did.
local function importExisting()
  local adb, _, err = dependencies()
  if not adb then say(err) return end
  local house = market()
  local saved = adb:SavedHouse(house)
  if not saved then say("No existing AHDB scans for " .. house .. ".") return end
  local keys = {}
  for id in pairs(saved.items or {}) do keys[id] = true end
  for id in pairs(saved.daily or {}) do keys[id] = true end
  local index = {}
  local now = GetServerTime()
  local maxAge = settings.importMaxAgeHours
  for id in pairs(keys) do
    local p = adb:LastPrice(tonumber(id) or id, house)
    if type(p) == "table" and tonumber(p[1]) and tonumber(p[2]) and tonumber(p[4]) then
      local age = now - tonumber(p[1])
      if age >= 0 and (maxAge == 0 or age <= maxAge * 3600) then
        addPrice(index, id, p[2], p[4])
      end
    end
  end
  local ok, message = importPrices(index, house, "stored AHDB history")
  if not ok then say("Backfill failed: " .. message) else say(message) end
end

local function register()
  if installed then return end
  local adb, _, err = dependencies()
  if not adb then say(err) return end
  adb:Listen("SCAN_DATA", onScan)
  installed = true
  say("Listening for completed AHDB full scans. Auctionator full scans are not required.")
end

local function status()
  say(string.format("%s | enabled=%s | faction=%s | backfill age=%sh",
    installed and "listener active" or "listener inactive",
    tostring(settings.enabled), market(), tostring(settings.importMaxAgeHours)))
  local last = settings.lastImport
  if last then
    say(string.format("Last import: %s, %d items, %s, %s",
      last.house or "?", last.items or 0, date("%Y-%m-%d %H:%M", last.timestamp or 0), last.via or "?"))
  end
end

SLASH_AHDBAUCTIONATORSYNC1 = "/ahsync"
SlashCmdList.AHDBAUCTIONATORSYNC = function(message)
  if not settings then initSaved() end
  local command, arg = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")
  command, arg = (command or ""):lower(), (arg or ""):lower()
  if command == "import" then
    importExisting()
  elseif command == "on" then
    settings.enabled = true
    say("Automatic syncing enabled.")
  elseif command == "off" then
    settings.enabled = false
    say("Automatic syncing disabled.")
  elseif command == "age" and tonumber(arg) and tonumber(arg) >= 0 then
    settings.importMaxAgeHours = tonumber(arg)
    say("Max age for manual historical backfill is now " .. arg .. " hours (0 = unlimited).")
  elseif command == "help" then
    say("Commands: /ahsync import | on | off | age HOURS | status")
  elseif command == "status" or command == "" then
    status()
    say("Commands: /ahsync import | on | off | age HOURS | status")
  else
    say("Unknown command. /ahsync status for help.")
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == ADDON then
    initSaved()
  elseif event == "PLAYER_LOGIN" then
    if not settings then initSaved() end
    register()
  end
end)
