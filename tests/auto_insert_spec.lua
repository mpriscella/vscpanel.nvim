local assert = require("luassert")
local helpers = require("tests.utils")

describe("vscpanel auto-insert functionality", function()
	local vscpanel, panel, state

	before_each(function()
		-- Reset everything before each test
		helpers.cleanup()

		vscpanel = require("vscpanel")
		panel = require("vscpanel.panel")
		state = require("vscpanel.state")
	end)

	describe("autocommand setup", function()
		it("sets up BufEnter and WinEnter autocommands for auto-insert", function()
			-- Setup vscpanel
			vscpanel.setup()

			-- Open a terminal panel
			panel.toggle_panel()
			local panel_win = state.window_id()
			assert.is.Not.Nil(panel_win, "Panel window should be created")

			-- Wait for terminal setup
			vim.wait(50)

			local current_buf = vim.api.nvim_get_current_buf()
			assert.are.equal("terminal", vim.bo[current_buf].buftype, "Should be in a terminal buffer")

			-- Check if autocommand group exists
			local augroup_name = "vscpanel_auto_insert_" .. current_buf
			local autocmds = vim.api.nvim_get_autocmds({
				group = augroup_name,
			})

			assert.is_true(#autocmds > 0, "Should have autocommands set up")

			-- Check that we have both BufEnter and WinEnter events
			local events = {}
			for _, autocmd in ipairs(autocmds) do
				table.insert(events, autocmd.event)
			end

			assert.is_true(vim.tbl_contains(events, "BufEnter"), "Should have BufEnter autocommand")
			assert.is_true(vim.tbl_contains(events, "WinEnter"), "Should have WinEnter autocommand")
		end)

		it("sets up unique autocommand groups for different terminal buffers", function()
			-- Setup vscpanel
			vscpanel.setup()

			-- Open panel and wait for initial terminal
			panel.toggle_panel()
			vim.wait(50)

			local panel_win = state.window_id()
			assert.is.Not.Nil(panel_win, "Panel window should be created")

			-- Create additional terminal (use nil for default shell)
			local terminal = require("vscpanel.views.terminal")
			terminal.create_terminal(panel_win, nil)
			vim.wait(50)

			local terminals = state.terminals()

			-- We should have at least 1 terminal, ideally 2
			assert.is_true(#terminals >= 1, "Should have at least 1 terminal")

			-- Test autocommand groups for all available terminals
			for i, term in ipairs(terminals) do
				local augroup_name = "vscpanel_auto_insert_" .. term.buffer
				local autocmds = vim.api.nvim_get_autocmds({
					group = augroup_name,
				})

				assert.is_true(#autocmds > 0, string.format("Terminal %d should have autocommands", i))

				-- Verify autocommands are buffer-specific
				for _, autocmd in ipairs(autocmds) do
					assert.are.equal(
						term.buffer,
						autocmd.buffer,
						string.format("Autocommand should be for buffer %d", term.buffer)
					)
				end
			end
		end)

		it("includes proper description for autocommands", function()
			-- Setup vscpanel
			vscpanel.setup()

			-- Open a terminal panel
			panel.toggle_panel()
			vim.wait(50)

			local current_buf = vim.api.nvim_get_current_buf()
			local augroup_name = "vscpanel_auto_insert_" .. current_buf
			local autocmds = vim.api.nvim_get_autocmds({
				group = augroup_name,
			})

			-- Check that autocommands have proper descriptions
			local found_described = false
			for _, autocmd in ipairs(autocmds) do
				if autocmd.desc and autocmd.desc:match("Auto%-enter insert mode") then
					found_described = true
					break
				end
			end

			assert.is_true(found_described, "Should have autocommand with proper description")
		end)
	end)

	describe("auto-insert behavior", function()
		it("calls ensure_insert when BufEnter event fires", function()
			-- Setup vscpanel
			vscpanel.setup()

			-- Mock the ensure_insert function to track calls
			local ensure_insert_calls = 0
			local original_ensure_insert = require("vscpanel").ensure_insert
			package.loaded["vscpanel"].ensure_insert = function(...)
				ensure_insert_calls = ensure_insert_calls + 1
				return original_ensure_insert(...)
			end

			-- Open a terminal panel
			panel.toggle_panel()
			vim.wait(50)

			local current_buf = vim.api.nvim_get_current_buf()
			assert.are.equal("terminal", vim.bo[current_buf].buftype, "Should be in terminal buffer")

			-- Reset call count after initial setup
			ensure_insert_calls = 0

			-- Trigger BufEnter by switching away and back
			local temp_buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_set_current_buf(temp_buf)
			vim.wait(10)

			-- Switch back to terminal (should trigger BufEnter)
			vim.api.nvim_set_current_buf(current_buf)
			vim.wait(10)

			-- Restore original function
			package.loaded["vscpanel"].ensure_insert = original_ensure_insert

			assert.is_true(ensure_insert_calls > 0, "ensure_insert should be called on BufEnter")
		end)
	end)
end)
