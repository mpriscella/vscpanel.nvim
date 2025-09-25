run-tests:
  act -W .github/workflows/test.yaml

run-unit-tests:
  nvim --headless -u tests/minimal_init.lua \
    -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua', output = 'nvim' }" \
    -c "qa!"

gen-docs:
  nvim --headless -c "helptags doc/" -c "qa!"

check-docs:
  @echo "Checking documentation format..."
  @grep -q "*vscpanel.txt*" doc/vscpanel.txt && echo "✓ Help file header found" || echo "✗ Missing help file header"
  @grep -q "==============================================================================" doc/vscpanel.txt && echo "✓ Section separators found" || echo "✗ Missing section separators"
  @grep -q "|vscpanel-" doc/vscpanel.txt && echo "✓ Help tags found" || echo "✗ Missing help tags"

test-docs:
  nvim --headless -c "helptags doc/" -c "help vscpanel" -c "qa!"

docs: gen-docs check-docs test-docs
  @echo "Documentation generation complete!"

lint:
  luacheck lua/ --globals vim

health:
  nvim --headless -u tests/minimal_init.lua \
    -c "lua require('vscpanel').setup()" \
    -c "checkhealth vscpanel" \
    -c "qa!"

check: run-tests lint docs health
  @echo "All checks passed!"
