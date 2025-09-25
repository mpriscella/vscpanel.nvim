local assert = require("luassert")

describe("vscpanel active terminal indicator", function()
	local vscpanel, tabs, state
	local test_utils = require("tests.utils")

	before_each(function()
		test_utils.cleanup()

		vscpanel = require("vscpanel")
		tabs = require("vscpanel.views.terminal.tabs")
		state = require("vscpanel.state")

		-- Setup plugin with custom close icon for testing.
		vscpanel.setup({
			icons = {
				close_terminal = "x",
			},
		})
	end)

	describe("active terminal indicator display", function()
		it("shows indicator for active terminal", function()
			-- Create mock terminals
			local buf1 = vim.api.nvim_create_buf(false, true)
			local buf2 = vim.api.nvim_create_buf(false, true)

			state.dispatch("add_terminal", buf1, "Terminal 1")
			state.dispatch("add_terminal", buf2, "Terminal 2")

			-- Set terminal 1 as active.
			state.dispatch("set_active_terminal", buf1)

			-- Get the terminal lines
			local lines = tabs.generate_tabs_content()

			-- Verify that terminal 1 has the indicator and terminal 2 doesn't
			assert.is.Not.Nil(lines)
			assert.are.equal(2, #lines)

			-- Active terminal should have "│" indicator
			assert.is_true(lines[1]:match("^│") ~= nil, "Active terminal should have │ indicator")

			-- Non-active terminal should have space indicator
			assert.is_true(lines[2]:match("^ ") ~= nil, "Non-active terminal should have space indicator")
			assert.is_false(lines[2]:match("^│") ~= nil, "Non-active terminal should not have │ indicator")
		end)

		it("switches indicator when active terminal changes", function()
			-- Create mock terminals
			local buf1 = vim.api.nvim_create_buf(false, true)
			local buf2 = vim.api.nvim_create_buf(false, true)

			-- Mock the state
			state.dispatch("add_terminal", buf1, "Terminal 1")
			state.dispatch("add_terminal", buf2, "Terminal 2")

			-- Set terminal 1 as active
			state.dispatch("set_active_terminal", buf1)
			local lines1 = tabs.generate_tabs_content()

			-- Set terminal 2 as active
			state.dispatch("set_active_terminal", buf2)
			local lines2 = tabs.generate_tabs_content()

			-- Verify indicator switched
			assert.is_true(lines1[1]:match("^│") ~= nil, "First terminal should be active initially")
			assert.is_true(lines1[2]:match("^ ") ~= nil, "Second terminal should be inactive initially")

			assert.is_true(lines2[1]:match("^ ") ~= nil, "First terminal should be inactive after switch")
			assert.is_true(lines2[2]:match("^│") ~= nil, "Second terminal should be active after switch")
		end)

		--- TODO: I almost removed this test, and may still remove it, but in normal usage there shouldn't be a scenario
		--- where no terminal is active when the panel is open. Yet we're able to set active terminal to nil. Maybe we
		--- enforce that terminal is non-nil in the state manager.
		it("shows no indicator when no terminal is active", function()
			-- Create mock terminals
			local buf1 = vim.api.nvim_create_buf(false, true)
			local buf2 = vim.api.nvim_create_buf(false, true)

			-- Mock the state
			state.dispatch("add_terminal", buf1, "Terminal 1")
			state.dispatch("add_terminal", buf2, "Terminal 2")

			-- Set no active terminal
			state.dispatch("set_active_terminal", nil)
			local lines = tabs.generate_tabs_content()

			-- Verify no terminal has the indicator
			assert.is_true(lines[1]:match("^ ") ~= nil, "First terminal should not be active")
			assert.is_false(lines[1]:match("^│") ~= nil, "First terminal should not have indicator")

			assert.is_true(lines[2]:match("^ ") ~= nil, "Second terminal should not be active")
			assert.is_false(lines[2]:match("^│") ~= nil, "Second terminal should not have indicator")
		end)

		--- TODO: Is this really a concern? Seems silly, and maybe this test can be removed.
		it("preserves indicator in line formatting with close icons", function()
			-- Create mock terminal
			local buf = vim.api.nvim_create_buf(false, true)

			-- Mock the state
			state.dispatch("add_terminal", buf, "Test")

			-- Set as active terminal
			state.dispatch("set_active_terminal", buf)
			local lines = tabs.generate_tabs_content()

			-- Verify line format: check if line contains the expected parts
			assert.is.Not.Nil(lines[1])
			assert.is.Not.Nil(string.find(lines[1], "│", 1, true), "Line should contain pipe indicator")
			assert.is.Not.Nil(string.find(lines[1], "Test", 1, true), "Line should contain 'Test'")
			assert.is_true(lines[1]:match("x$") ~= nil, "Line should end with close icon")
		end)
	end)
end)
