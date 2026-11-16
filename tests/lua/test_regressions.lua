local mock = dofile(TEST_ROOT .. '/support/mock.lua')
return {
  current_price_can_increase_after_a_scan = function()
    local ctx = mock.new()
    ctx:scan()
    ctx.env.AuctionDB.scanStart = 102
    ctx:scan({3000, 1000, 0, 0})
    assert(ctx.calls == 2)
    assert(ctx.env.Auctionator.Database.db['10940'].m == 200,
      'new current price must replace a lower earlier price')
  end,
}
