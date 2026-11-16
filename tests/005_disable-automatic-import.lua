-- Turning sync off prevents automatic imports.
local ctx = mock.new()
ctx:command('off')
ctx:scan()
assert(ctx.calls == 0, 'Automatic import ran while sync was disabled')
