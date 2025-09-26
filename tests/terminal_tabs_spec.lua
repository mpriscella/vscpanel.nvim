local assert = require("luassert")

describe("terminal tabs", function()
	local panel, tabs, terminal, state, vscpanel
	local test_utils = require("tests.utils")

	before_each(function()
		test_utils.cleanup()

		panel = require("vscpanel.panel")
		tabs = require("vscpanel.views.terminal.tabs")
		terminal = require("vscpanel.views.terminal")
		state = require("vscpanel.state")
		vscpanel = require("vscpanel")

		vscpanel.setup({
			icons = {
				terminal = {
					close_terminal = "x",
				},
			},
		})
		terminal.setup()
	end)

	describe("active terminal indicator", function()
		it("displays on active terminal", function()
			local window = panel.open()

			terminal.create_terminal(window)
			terminal.create_terminal(window)

			local lines = tabs.generate_tabs_content()
			assert.is.Not.Nil(lines, "Tabs content shouldn't be nil")
			assert.are.equal(2, #lines, "There should be two tabs in the tabs window")

			assert.is_true(lines[1]:match("^ ") ~= nil, "Inactive terminal should have no indicator")
			assert.is_false(lines[1]:match("^│") ~= nil, "Inactive terminal should not have │ indicator")

			assert.is_true(lines[2]:match("^│") ~= nil, "Active terminal should have │ indicator")
		end)

		it("switches when active terminal changes", function()
			local window = panel.open()

			local term1 = terminal.create_terminal(window)
			local term2 = terminal.create_terminal(window)

			-- Set terminal 1 as active
			state.dispatch("set_active_terminal", term1)
			local lines1 = tabs.generate_tabs_content()

			-- Set terminal 2 as active
			state.dispatch("set_active_terminal", term2)
			local lines2 = tabs.generate_tabs_content()

			-- Verify indicator switched
			assert.is_true(lines1[1]:match("^│") ~= nil, "First terminal should be active initially")
			assert.is_true(lines1[2]:match("^ ") ~= nil, "Second terminal should be inactive initially")

			assert.is_true(lines2[1]:match("^ ") ~= nil, "First terminal should be inactive after switch")
			assert.is_true(lines2[2]:match("^│") ~= nil, "Second terminal should be active after switch")
		end)
	end)
end)
