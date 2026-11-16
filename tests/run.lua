-- Each test file returns named cases. Every case creates its own mock client.
TEST_ROOT = arg[0]:match('^(.*)/[^/]+$') or '.'
local passed, failed = 0, 0
assert(#arg > 0, 'No test files supplied')
for _, path in ipairs(arg) do
  local cases = dofile(path)
  local names = {}
  for name in pairs(cases) do names[#names + 1] = name end
  table.sort(names)
  assert(#names > 0, 'No cases in ' .. path)
  for _, name in ipairs(names) do
    local ok, err = xpcall(cases[name], debug.traceback)
    if ok then
      passed = passed + 1
      io.write('PASS: ' .. path .. ' / ' .. name .. '\n')
    else
      failed = failed + 1
      io.stderr:write('FAIL: ' .. path .. ' / ' .. name .. '\n' .. err .. '\n')
    end
  end
end
io.write(string.format('%d passed, %d failed\n', passed, failed))
if failed > 0 then os.exit(1) end
