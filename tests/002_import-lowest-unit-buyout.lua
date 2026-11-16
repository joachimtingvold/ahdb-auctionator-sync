-- Import the lowest per-item buyout, total quantity, and persistent price.
local ctx = mock.new()
ctx:scan()
assert(ctx.calls == 1, 'Expected one Auctionator import for a completed scan')
assert(ctx.lastData['10940'][1].price == 100, 'Expected lowest unit buyout of 100 copper')
assert(ctx.lastData['10940'][1].available == 15, 'Expected total buyout quantity of 15')
assert(ctx.env.Auctionator.Database.db['10940'].m == 100, 'Current price was not saved')
assert(ctx.lastData['1234'] == nil, 'Bid-only listings must not contribute a buyout price')
