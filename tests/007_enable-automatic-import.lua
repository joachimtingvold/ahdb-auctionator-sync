-- Turning sync back on restores automatic imports.
local ctx = mock.new()
ctx:command('off')
ctx:command('on')
ctx:scan()
assert(ctx.env.AHDBAuctionatorSyncDB.enabled == true, 'Sync setting was not enabled')
assert(ctx.calls == 1, 'Expected automatic import after enabling sync')
