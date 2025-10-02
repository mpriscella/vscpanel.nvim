# Run GitHub Workflow locally.
run-workflow:
  @act -W .github/workflows/test.yaml

# Run Unit tests.
run-unit-tests:
  @nvim --headless -u tests/minimal_init.lua \
    -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua', output = 'nvim' }" \
    -c "qa!"

# Generate and test documentation.
docs:
  @echo "Generating documentation..."
  @nvim --headless -u NONE \
    -c "helptags doc/" \
    -c "quit"

  @echo "Testing documentation..."
  @nvim --headless -u NONE \
    -c "help vscpanel" \
    -c "quit" 2>&1 | grep -q "vscpanel" || (echo "Doc test failed!" && exit 1)

  @echo "Documentation OK"

# Run luacheck
lint:
  @luacheck lua/ --globals vim

# Check plugin health.
health:
  @nvim --headless -u tests/minimal_init.lua \
    -c "checkhealth vscpanel" \
    -c "qa!"

# Run all checks.
check: run-workflow lint docs health
  @echo "All checks passed!"
