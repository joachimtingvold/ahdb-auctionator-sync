local mock = dofile(TEST_ROOT .. '/support/mock.lua')
return {
  registers_listener = function()
    assert(mock.new().events.SCAN_DATA, 'completed-scan listener must register')
  end,
  aggregates_buyouts_per_item = function()
    local ctx = mock.new()
    ctx:scan()
    assert(ctx.calls == 1, 'process scan once')
    assert(ctx.lastData['10940'][1].price == 100, 'lowest per-unit buyout')
    assert(ctx.lastData['10940'][1].available == 15, 'total buyout quantity')
    assert(ctx.env.Auctionator.Database.db['10940'].m == 100, 'persist current price')
    assert(ctx.lastData['1234'] == nil, 'exclude bid-only listings')
  end,
  skips_duplicate_scan = function()
    local ctx = mock.new()
    ctx:scan()
    ctx:scan()
    assert(ctx.calls == 1, 'do not import the same scan twice')
  end,
  keeps_neutral_market_separate = function()
    local ctx = mock.new()
    ctx.env.AuctionDB.scanHouseName = 'Neutral'
    ctx:scan()
    assert(ctx.calls == 0, 'neutral prices must not enter faction database')
  end,
}
