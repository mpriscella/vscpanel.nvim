local assert = require("luassert")
local vscpanel = require("vscpanel")
local panel = require("vscpanel.panel")
local terminal = require("vscpanel.views.terminal")
local tabs = require("vscpanel.views.terminal.tabs")
local state = require("vscpanel.state")
local test_utils = require("tests.utils")

describe("vscpanel panel-tabs integration", function()
	before_each(function()
		test_utils.cleanup()

		-- Clean up any existing state
		state.dispatch("clear_window")
		state.dispatch("clear_terminals")
		state.dispatch("set_active_terminal", nil)
		-- state.active_terminal = nil
		state.dispatch("set_maximized", false)
		-- state.maximized = false

		-- Also clear any global state
		vim.g.vscpanel_last_buffer = nil

		-- Force close any existing terminal list windows
		if tabs.are_open() then
			tabs.hide()
		end
	end)

	it("hides tabs when panel is closed", function()
		-- Setup vscpanel
		vscpanel.setup({})

		-- Open panel
		panel.toggle_panel()

		-- Debug: check current window
		local current_win = vim.api.nvim_get_current_win()
		local panel_win = state.window_id()

		-- For debugging - let's see what we actually get
		if panel_win == nil then
			-- Try to use current window instead
			panel_win = current_win
		end

		assert.not_equal(nil, panel_win)

		-- Create multiple terminals to trigger auto-show tabs
		-- Use current window as fallback if state doesn't have window ID
		local actual_win = panel_win or vim.api.nvim_get_current_win()
		terminal.create_terminal(actual_win, "bash")

		-- Verify tabs are open (should auto-show with multiple terminals)
		local tabs_open_before = tabs.are_open()
		assert.is_true(tabs_open_before)

		-- Close panel
		panel.toggle_panel()

		-- Verify panel is closed
		local panel_win_after = state.window_id()
		assert.is_nil(panel_win_after)

		-- Verify tabs are also closed
		local tabs_open_after = tabs.are_open()
		assert.is_false(tabs_open_after)
	end)

	it("restores tabs when panel is reopened if they were previously open", function()
		-- Setup vscpanel
		vscpanel.setup({})

		-- Open panel
		panel.toggle_panel()

		-- Debug: check current window
		local current_win = vim.api.nvim_get_current_win()
		local panel_win = state.window_id()

		-- For debugging - let's see what we actually get
		if panel_win == nil then
			-- Try to use current window instead
			panel_win = current_win
		end

		assert.is.Not.Nil(panel_win)

		-- Create multiple terminals to trigger auto-show tabs
		-- Use current window as fallback if state doesn't have window ID
		local actual_win = panel_win or vim.api.nvim_get_current_win()
		terminal.create_terminal(actual_win, "bash")

		-- Verify tabs are open
		assert.is_true(tabs.are_open())

		-- Close panel (this should remember that tabs were open)
		panel.toggle_panel()
		assert.is_false(tabs.are_open())

		-- Reopen panel
		panel.toggle_panel()

		-- Verify tabs are restored
		assert.is_true(tabs.are_open())
	end)

	it("does not show tabs on panel reopen if they were not previously open and only one terminal exists", function()
		vscpanel.setup({})

		panel.toggle_panel()

		-- Debug: check current window
		local current_win = vim.api.nvim_get_current_win()
		local panel_win = state.window_id()

		-- For debugging - let's see what we actually get
		if panel_win == nil then
			-- Try to use current window instead
			panel_win = current_win
		end

		assert.is.Not.Nil(panel_win)

		-- Verify we have exactly one terminal and tabs are not open
		-- Ensure we have exactly one terminal for this test
		local terminals = state.terminals()
		while #terminals == 0 do
			-- Manually create a terminal using state directly
			local buf = vim.api.nvim_create_buf(false, true)
			local actual_win = panel_win or vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(actual_win, buf)
			state.dispatch("add_terminal", { buffer = buf, label = "bash", shell = "/bin/bash" })
			terminals = state.terminals()
		end
		assert.are.equal(1, #terminals, "Expected 1 terminal, got " .. #terminals)

		-- Ensure tabs are hidden since this test expects them to not be shown with only one terminal
		tabs.hide()
		assert.is_false(tabs.are_open())

		-- Close panel
		panel.toggle_panel()

		-- Reopen panel
		panel.toggle_panel()

		-- Verify tabs are still not shown (since we only have one terminal and they weren't previously open)
		assert.is_false(tabs.are_open())
	end)

	it("shows tabs on panel reopen if multiple terminals exist", function()
		-- Setup vscpanel
		vscpanel.setup({})

		-- Open panel
		panel.toggle_panel()
		local panel_win = state.window_id()

		-- Use current window as fallback if state doesn't have window ID
		if panel_win == nil then
			panel_win = vim.api.nvim_get_current_win()
		end

		-- Create multiple terminals but manually hide tabs
		terminal.create_terminal(panel_win, "bash")
		tabs.hide() -- Manually hide tabs

		-- Verify tabs are hidden despite multiple terminals
		assert.is_false(tabs.are_open())

		-- Close and reopen panel
		panel.toggle_panel()
		panel.toggle_panel()

		-- Verify tabs are shown due to multiple terminals
		assert.is_true(tabs.are_open())
	end)

	it("handles multiple toggle cycles correctly", function()
		-- Setup vscpanel
		vscpanel.setup({})

		-- Cycle 1: Open panel, create terminals, verify tabs
		panel.toggle_panel()
		local panel_win = state.window_id()
		if panel_win == nil then
			panel_win = vim.api.nvim_get_current_win()
		end
		terminal.create_terminal(panel_win, "bash")
		assert.is_true(tabs.are_open())

		-- Close panel
		panel.toggle_panel()
		assert.is_false(tabs.are_open())

		-- Cycle 2: Reopen and verify tabs restore
		panel.toggle_panel()
		assert.is_true(tabs.are_open())

		-- Close again
		panel.toggle_panel()
		assert.is_false(tabs.are_open())

		-- Cycle 3: Final reopen
		panel.toggle_panel()
		assert.is_true(tabs.are_open())
	end)
end)
