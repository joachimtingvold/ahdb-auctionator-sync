-- Keep neutral auction-house prices out of the faction database.
local ctx = mock.new()
ctx.env.AuctionDB.scanHouseName = 'Neutral'
ctx:scan()
assert(ctx.calls == 0, 'Neutral prices must not be imported into the faction database')
