-- Manual imports accept recent prices and exclude history over the default age limit.
local ctx = mock.new()
ctx:command('import')
assert(ctx.calls == 1, 'Expected one manual history import')
assert(ctx.env.Auctionator.Database.db['10940'].m == 125, 'Recent historical price was not imported')
assert(ctx.env.Auctionator.Database.db['10978'] == nil, 'History older than the age limit was imported')
