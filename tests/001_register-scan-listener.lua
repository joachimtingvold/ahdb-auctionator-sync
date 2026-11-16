-- Register a listener for completed AHDB scans.
local ctx = mock.new()
assert(ctx.events.SCAN_DATA, 'Completed-scan listener was not registered')
