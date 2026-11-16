local mock = dofile(TEST_ROOT .. '/support/mock.lua')
return {
  excludes_old_prices_by_default = function()
    local ctx = mock.new()
    ctx:command('import')
    assert(ctx.calls == 1)
    assert(ctx.env.Auctionator.Database.db['10940'].m == 125)
    assert(ctx.env.Auctionator.Database.db['10978'] == nil, 'exclude old history')
  end,
  accepts_unlimited_history = function()
    local ctx = mock.new()
    ctx:command('age 0')
    ctx:command('import')
    assert(ctx.env.Auctionator.Database.db['10978'].m == 500)
    assert(ctx.env.AHDBAuctionatorSyncDB.lastImport.items == 2)
  end,
}
