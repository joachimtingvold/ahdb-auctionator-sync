-- Import a completed scan only once, even if its callback repeats.
local ctx = mock.new()
ctx:scan()
ctx:scan()
assert(ctx.calls == 1, 'The same completed scan was imported more than once')
