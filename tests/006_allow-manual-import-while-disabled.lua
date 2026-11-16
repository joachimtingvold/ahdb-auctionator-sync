-- Manual imports remain available when automatic sync is disabled.
local ctx = mock.new()
ctx:command('off')
ctx:command('import')
assert(ctx.calls == 1, 'Manual import should work while automatic sync is disabled')
