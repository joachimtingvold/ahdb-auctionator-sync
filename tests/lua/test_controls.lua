local mock = dofile(TEST_ROOT .. '/support/mock.lua')
return {
  disables_automatic_import = function()
    local ctx = mock.new()
    ctx:command('off')
    ctx:scan()
    assert(ctx.calls == 0, 'disabled automatic import')
  end,
  allows_manual_import_while_disabled = function()
    local ctx = mock.new()
    ctx:command('off')
    ctx:command('import')
    assert(ctx.calls == 1, 'manual import still works')
  end,
  enables_automatic_import = function()
    local ctx = mock.new()
    ctx:command('off')
    ctx:command('on')
    ctx:scan()
    assert(ctx.env.AHDBAuctionatorSyncDB.enabled == true)
    assert(ctx.calls == 1)
  end,
}
