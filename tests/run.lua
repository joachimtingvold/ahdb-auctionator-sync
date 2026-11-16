-- Shared mock client and runner; numbered files below each contain one test.
local mock = {}

function mock.new()
  local ctx = {now = 1794758400, calls = 0, messages = {}, events = {}}
  local env = setmetatable({}, {__index = _G})
  env._G = env
  env.print = function(message) ctx.messages[#ctx.messages + 1] = tostring(message) end
  env.UnitFactionGroup = function() return 'Alliance' end
  env.GetServerTime = function() return ctx.now end
  env.date = os.date
  env.SlashCmdList = {}
  env.CreateFrame = function()
    local frame = {}
    function frame:RegisterEvent() end
    function frame:SetScript(event, callback) self[event] = callback end
    ctx.frame = frame
    return frame
  end
  env.Auctionator = {Database = {db = {}}}
  function env.Auctionator.Database:ProcessScan(data)
    ctx.calls = ctx.calls + 1
    ctx.lastData = data
    for key, prices in pairs(data) do
      local record = self.db[key] or {m = 0}
      record.m = math.min(record.m > 0 and record.m or math.huge, prices[1].price)
      self.db[key] = record
    end
  end
  ctx.history = {
    [10940] = {ctx.now - 30, 125, 150, 20},
    [10978] = {ctx.now - 86400 * 5, 500, 500, 2},
  }
  env.AuctionDB = {scanHouseName = 'Alliance', scanStart = 101,
    saved = {items = {[10940] = true, [10978] = true}, daily = {}}}
  function env.AuctionDB:Listen(name, callback) ctx.events[name] = callback end
  function env.AuctionDB:LastPrice(id) return ctx.history[id] end
  function env.AuctionDB:SavedHouse(house) return house == 'Alliance' and self.saved or nil end
  local chunk = assert(loadfile('AHDBAuctionatorSync.lua'))
  setfenv(chunk, env)()
  ctx.frame.OnEvent(ctx.frame, 'ADDON_LOADED', 'AHDBAuctionatorSync')
  ctx.frame.OnEvent(ctx.frame, 'PLAYER_LOGIN')
  ctx.env = env
  function ctx:scan(buyout)
    self.events.SCAN_DATA(env.AuctionDB, {n = 4,
      item = {10940, 10940, 10940, 1234}, count = {10, 5, 1, 2},
      buyout = buyout or {2100, 500, 0, 0}})
  end
  function ctx:command(message) env.SlashCmdList.AHDBAUCTIONATORSYNC(message) end
  return ctx
end


assert(#arg > 0, 'No numbered Lua test files supplied')
table.sort(arg)
local passed, failed = 0, 0
local numbers = {}
for _, path in ipairs(arg) do
  local name = path:match('([^/]+)$')
  local number = name:match('^(%d%d%d)_')
  assert(number and not numbers[number], 'Missing or duplicate test number: ' .. path)
  numbers[number] = true
  io.write('RUN: ' .. name .. '\n')
  local ok, err = xpcall(function()
    local chunk = assert(loadfile(path))
    setfenv(chunk, setmetatable({mock = mock}, {__index = _G}))()
  end, debug.traceback)
  if ok then
    passed = passed + 1
    io.write('PASS: ' .. name .. '\n')
  else
    failed = failed + 1
    io.stderr:write('FAIL: ' .. name .. '\n' .. err .. '\n')
  end
end
io.write(string.format('%d passed, %d failed\n', passed, failed))
if failed > 0 then os.exit(1) end
