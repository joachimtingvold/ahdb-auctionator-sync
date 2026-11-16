-- An age limit of zero imports older stored prices too.
local ctx = mock.new()
ctx:command('age 0')
ctx:command('import')
assert(ctx.env.Auctionator.Database.db['10978'].m == 500, 'Unlimited history did not import the old price')
assert(ctx.env.AHDBAuctionatorSyncDB.lastImport.items == 2, 'Expected two items in the import summary')
