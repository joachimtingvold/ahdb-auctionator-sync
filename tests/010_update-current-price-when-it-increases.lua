-- Regression: a higher current price must replace an earlier lower scan price.
local ctx = mock.new()
ctx:scan()
ctx.env.AuctionDB.scanStart = 102
ctx:scan({3000, 1000, 0, 0})
assert(ctx.calls == 2, 'Expected both distinct scans to be imported')
assert(ctx.env.Auctionator.Database.db['10940'].m == 200,
  'Current price must rise to 200 copper after the second scan')
