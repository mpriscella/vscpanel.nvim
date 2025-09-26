local assert = require("luassert")
local helpers = require("tests.utils")

describe("vscpanel terminal deletion functionality", function()
	local vscpanel, panel, terminal, tabs, state

	before_each(function()
		-- Reset everything before each test
		helpers.cleanup()

		vscpanel = require("vscpanel")
		panel = require("vscpanel.panel")
		terminal = require("vscpanel.views.terminal")
		tabs = require("vscpanel.views.terminal.tabs")
		state = require("vscpanel.state")

		vscpanel.setup({
			size = 10,
			position = "bottom",
			icons = {
				close_terminal = "x",
			},
		})
	end)

	describe("d key terminal deletion", function()
		it("deletes terminal when 'd' key is pressed in tabs window", function()
			panel.toggle_panel()

			-- Get panel window with fallback
			local panel_win = state.window_id() or vim.api.nvim_get_current_win()
			assert.is.Not.Nil(panel_win)

			-- Create one additional terminal to ensure we have at least 2
			terminal.create_terminal(panel_win, "bash")

			-- Verify we have at least 2 terminals now
			local updated_terminals = state.terminals()
			assert.is_true(#updated_terminals >= 2, "Should have at least 2 terminals for this test")

			-- Show tabs
			tabs.show_tabs()
			assert.is_true(tabs.are_open(), "Tabs should be open")

			-- Get the tabs window and buffer
			local tabs_win = nil
			local tabs_buf = nil

			-- Find the tabs window (it should be a different window from the panel)
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local buf = vim.api.nvim_win_get_buf(win)
				if vim.bo[buf].buftype == "nofile" and win ~= panel_win then
					tabs_win = win
					tabs_buf = buf
					break
				end
			end

			assert.is.Not.Nil(tabs_win, "Should find tabs window")
			assert.is.Not.Nil(tabs_buf, "Should find tabs buffer")

			-- Focus the tabs window and position cursor on first terminal
			vim.api.nvim_set_current_win(tabs_win)
			vim.api.nvim_win_set_cursor(tabs_win, { 1, 0 })

			-- Get the buffer ID of the first terminal before deletion
			local first_terminal_buffer = updated_terminals[1].buffer

			-- Simulate pressing 'd' key by directly calling the mapped function
			-- We need to find the keymap and execute it
			local keymaps = vim.api.nvim_buf_get_keymap(tabs_buf, "n")
			local d_keymap = nil
			for _, map in ipairs(keymaps) do
				if map.lhs == "d" then
					d_keymap = map
					break
				end
			end

			assert.is.Not.Nil(d_keymap, "Should find 'd' keymap in tabs buffer")

			-- Execute the callback function for the 'd' key
			if d_keymap and d_keymap.callback then
				d_keymap.callback()
			elseif d_keymap then
				-- If it's a string command, execute it
				vim.cmd(d_keymap.rhs)
			end

			-- Verify the terminal was deleted
			local remaining_terminals = state.terminals()
			assert.are.equal(
				#updated_terminals - 1,
				#remaining_terminals,
				"Should have one less terminal after deletion"
			)

			-- Verify the correct terminal was deleted
			assert.is_false(vim.api.nvim_buf_is_valid(first_terminal_buffer), "First terminal buffer should be invalid")

			-- Verify the remaining terminal is not the deleted one
			for _, term in ipairs(remaining_terminals) do
				assert.Not.equal(first_terminal_buffer, term.buffer, "Remaining terminal should not be the deleted one")
			end
		end)

		it("hides tabs when only one terminal remains after deletion", function()
			-- Open panel and create multiple terminals
			panel.toggle_panel()

			local panel_win = state.window_id() or vim.api.nvim_get_current_win()

			-- Ensure we have at least 2 terminals (toggle_panel may create one)
			local initial_terminals = state.terminals()
			while #initial_terminals < 2 do
				terminal.create_terminal(panel_win, "bash")
				initial_terminals = state.terminals()
			end

			-- Show tabs
			tabs.show_tabs()
			assert.is_true(tabs.are_open(), "Tabs should be open initially")

			-- Delete one terminal using the close_terminal function directly
			-- (simulating what the 'd' key should do)
			terminal.close_terminal(1)

			-- Verify only one terminal remains
			local remaining_terminals = state.terminals()
			assert.are.equal(1, #remaining_terminals, "Should have 1 terminal after deletion")

			-- Verify tabs are automatically hidden when only one terminal remains
			assert.is_false(tabs.are_open(), "Tabs should be hidden when only one terminal remains")
		end)

		it("updates tabs display when multiple terminals remain after deletion", function()
			-- Open panel
			panel.toggle_panel()

			local panel_win = state.window_id() or vim.api.nvim_get_current_win()

			-- Ensure we have at least 3 terminals
			local initial_terminals = state.terminals()
			while #initial_terminals < 3 do
				terminal.create_terminal(panel_win, "bash")
				initial_terminals = state.terminals()
			end

			-- Verify we have at least 3 terminals
			assert.is_true(#initial_terminals >= 3, "Should have at least 3 terminals for this test")

			-- Show tabs
			tabs.show_tabs()
			assert.is_true(tabs.are_open(), "Tabs should be open")

			-- Delete one terminal
			terminal.close_terminal(2) -- Delete the middle terminal

			-- Verify we have one less terminal
			local remaining_terminals = state.terminals()
			assert.are.equal(
				#initial_terminals - 1,
				#remaining_terminals,
				"Should have one less terminal after deletion"
			)

			-- Verify tabs are still open (since we have multiple terminals)
			assert.is_true(tabs.are_open(), "Tabs should still be open with multiple terminals")
		end)

		it("handles deleting the active terminal correctly", function()
			-- Open panel
			panel.toggle_panel()

			local panel_win = state.window_id() or vim.api.nvim_get_current_win()

			-- Ensure we have at least 2 terminals
			local initial_terminals = state.terminals()
			while #initial_terminals < 2 do
				terminal.create_terminal(panel_win, "bash")
				initial_terminals = state.terminals()
			end
			local active_terminal = state.active_terminal()
			assert.is.Not.Nil(active_terminal, "Should have an active terminal")

			-- Find which line number corresponds to the active terminal
			local active_line = nil
			for i, term in ipairs(initial_terminals) do
				if term.buffer == active_terminal.buffer then
					active_line = i
					break
				end
			end
			assert.is.Not.Nil(active_line, "Should find active terminal in list")

			-- Delete the active terminal
			terminal.close_terminal(active_line)

			-- Verify the terminal was deleted
			local remaining_terminals = state.terminals()
			assert.are.equal(
				#initial_terminals - 1,
				#remaining_terminals,
				"Should have one less terminal after deletion"
			)

			-- Verify a new active terminal was set
			local new_active_terminal = state.active_terminal()
			assert.is.Not.Nil(new_active_terminal, "Should have a new active terminal")
			assert.Not.equal(active_terminal.buffer, new_active_terminal.buffer, "Active terminal should have changed")

			-- Verify the new active terminal is valid
			assert.is_true(vim.api.nvim_buf_is_valid(new_active_terminal.buffer), "New active terminal should be valid")
		end)

		it("handles terminal deletion through TermClose autocmd", function()
			-- This test verifies that the TermClose autocmd properly cleans up state
			panel.toggle_panel()

			local panel_win = state.window_id()

			-- Ensure we have at least 2 terminals
			local initial_terminals = state.terminals()
			while #initial_terminals < 2 do
				terminal.create_terminal(panel_win, "bash")
				initial_terminals = state.terminals()
			end

			assert.is_true(#initial_terminals >= 2, "Should have at least 2 terminals for this test")

			-- tabs.show_tabs()
			assert.is_true(tabs.are_open(), "Tabs should be open")

			local first_terminal_buffer = initial_terminals[1].buffer
			vim.api.nvim_buf_delete(first_terminal_buffer, { force = true })

			-- Verify the terminal was removed from state
			local remaining_terminals = state.terminals()
			assert.are.equal(
				#initial_terminals - 1,
				#remaining_terminals,
				"Should have one less terminal after buffer deletion"
			)

			-- Verify tabs are hidden (since only one terminal remains)
			assert.is_false(tabs.are_open(), "Tabs should be hidden after deletion")

			-- Verify the deleted buffer is no longer in the terminals list
			for _, term in ipairs(remaining_terminals) do
				assert.Not.equal(first_terminal_buffer, term.buffer, "Deleted buffer should not be in terminals list")
			end
		end)
	end)
end)
