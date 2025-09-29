# Run GitHub Workflow locally.
run-workflow:
  @act -W .github/workflows/test.yaml

# Run Unit tests.
run-unit-tests:
  @nvim --headless -u tests/minimal_init.lua \
    -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua', output = 'nvim' }" \
    -c "qa!"

# Generate documentation helptags.
gen-docs:
  @nvim --headless -c "helptags doc/" -c "qa!"

# Test whether the help documentation is properly loading.
test-docs:
  @nvim --headless -c "helptags doc/" -c "help vscpanel" -c "qa!"
  @echo "Documentation is good"

# Generate and test documentation.
docs: gen-docs test-docs
  @echo "Documentation generation complete!"

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
