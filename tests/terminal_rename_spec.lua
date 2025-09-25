local assert = require("luassert")
local helpers = require("tests.utils")

describe("vscpanel terminal rename functionality", function()
	local vscpanel, state

	before_each(function()
		-- Reset everything before each test
		helpers.cleanup()

		vscpanel = require("vscpanel")
		state = require("vscpanel.state")

		-- Setup with rename functionality enabled
		vscpanel.setup({
			size = 10,
			position = "bottom",
			icons = {
				close_terminal = "x",
			},
		})
	end)

	describe("terminal label management", function()
		it("sets and gets terminal labels correctly", function()
			-- Create a mock terminal buffer
			local buf = vim.api.nvim_create_buf(false, true)

			-- Add terminal to state
			state.dispatch("add_terminal", buf, vim.fs.basename(vim.o.shell))

			-- Verify initial label is the shell basename (not full path)
			local _, initial_label = state.terminal_label(buf)
			assert.equals(vim.fs.basename(vim.o.shell), initial_label)

			-- Set a custom label
			local success = state.dispatch("set_terminal_label", buf, "My Custom Terminal")

			assert.is_true(success)

			-- Verify the label was updated
			local _, updated_label = state.terminal_label(buf)
			assert.equals("My Custom Terminal", updated_label)

			-- Clean up
			-- Maybe this can be a function.
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end)
		it("returns false when setting label for non-existent terminal", function()
			local fake_buf_id = 99999
			local success = state.dispatch("set_terminal_label", fake_buf_id, "Test Label")
			assert.is_false(success)
		end)

		it("returns nil when getting label for non-existent terminal", function()
			local fake_buf_id = 99999
			local is_valid, _ = state.terminal_label(fake_buf_id)
			assert.is_false(is_valid)
		end)
	end)

	describe("display name generation", function()
		-- Helper function to test display name generation
		local function test_display_name_with_mock_terminal(custom_label, buffer_name)
			-- Create a mock terminal state
			local mock_buf = vim.api.nvim_create_buf(false, true)
			if buffer_name then
				vim.api.nvim_buf_set_name(mock_buf, buffer_name)
			end

			-- Add to state and set custom label if provided
			-- state.add_terminal(mock_buf)
			state.dispatch("add_terminal", mock_buf, vim.fs.basename(vim.o.shell))
			if custom_label then
				state.dispatch("set_terminal_label", mock_buf, custom_label)
			end

			-- Get the actual display name using the state function
			-- local display_name = state.get_terminal_label(mock_buf)
			local _, display_name = state.terminal_label(mock_buf)

			-- Clean up
			if vim.api.nvim_buf_is_valid(mock_buf) then
				vim.api.nvim_buf_delete(mock_buf, { force = true })
			end

			return display_name
		end

		-- Helper function to test the actual display logic from generate_terminal_lines
		local function test_generate_terminal_lines_display(custom_label, buffer_name)
			-- Create a mock terminal state
			local mock_buf = vim.api.nvim_create_buf(false, true)
			if buffer_name then
				vim.api.nvim_buf_set_name(mock_buf, buffer_name)
			end

			-- Add to state and set custom label if provided
			-- state.add_terminal(mock_buf)
			state.dispatch("add_terminal", mock_buf, vim.fs.basename(vim.o.shell))
			if custom_label then
				state.dispatch("set_terminal_label", mock_buf, custom_label)
			end

			-- Use the same logic as generate_terminal_lines
			local terminals = state.terminals()
			local terminal = terminals[1]

			local display_name
			if terminal.label and terminal.label ~= "" then
				display_name = terminal.label
			else
				local buf_name = vim.api.nvim_buf_get_name(terminal.buffer)
				display_name = buf_name ~= "" and vim.fn.fnamemodify(buf_name, ":t") or ("Terminal " .. terminal.buffer)
			end

			-- Clean up
			if vim.api.nvim_buf_is_valid(mock_buf) then
				vim.api.nvim_buf_delete(mock_buf, { force = true })
			end

			return display_name
		end

		it("uses custom label when set", function()
			local display_name = test_display_name_with_mock_terminal("My Custom Name")
			assert.equals("My Custom Name", display_name)
		end)

		it("falls back to shell default when no custom label", function()
			local display_name = test_display_name_with_mock_terminal(nil, "/path/to/test.lua")
			-- Should return the shell basename since no custom label is set
			assert.equals(vim.fs.basename(vim.o.shell), display_name)
		end)

		it("falls back to shell default when no buffer name", function()
			local display_name = test_display_name_with_mock_terminal(nil, nil)
			-- Should return the shell basename since no custom label is set
			assert.equals(vim.fs.basename(vim.o.shell), display_name)
		end)
		it("prefers custom label over buffer name", function()
			local display_name = test_display_name_with_mock_terminal("Custom", "/path/to/file.lua")
			assert.equals("Custom", display_name)
		end)

		-- Test the actual generate_terminal_lines display logic
		it("generate_terminal_lines uses custom label when set", function()
			local display_name = test_generate_terminal_lines_display("My Custom Terminal")
			assert.equals("My Custom Terminal", display_name)
		end)

		it("generate_terminal_lines falls back to buffer name when no custom label", function()
			-- Create a mock terminal state
			local mock_buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_name(mock_buf, "/path/to/test.lua")

			-- Add to state (this sets label to vim.o.shell by default)
			-- state.add_terminal(mock_buf)
			state.dispatch("add_terminal", mock_buf)

			-- Now clear the label to simulate the case where there's no custom label
			local terminals = state.terminals()
			terminals[1].label = "" -- Set to empty to trigger buffer name fallback

			local terminal = terminals[1]
			local display_name
			if terminal.label and terminal.label ~= "" then
				display_name = terminal.label
			else
				local buf_name = vim.api.nvim_buf_get_name(terminal.buffer)
				display_name = buf_name ~= "" and vim.fn.fnamemodify(buf_name, ":t") or ("Terminal " .. terminal.buffer)
			end

			-- Should now use buffer name
			assert.equals("test.lua", display_name)

			-- Clean up
			if vim.api.nvim_buf_is_valid(mock_buf) then
				vim.api.nvim_buf_delete(mock_buf, { force = true })
			end
		end)

		it("generate_terminal_lines falls back to Terminal X format when no buffer name", function()
			-- Create a mock terminal state
			local mock_buf = vim.api.nvim_create_buf(false, true)
			-- Don't set buffer name

			-- Add to state (this sets label to vim.o.shell by default)
			-- state.add_terminal(mock_buf)
			state.dispatch("add_terminal", mock_buf)

			-- Now clear the label to simulate the case where there's no custom label
			local terminals = state.terminals()
			terminals[1].label = "" -- Set to empty to trigger Terminal X fallback

			local terminal = terminals[1]
			local display_name
			if terminal.label and terminal.label ~= "" then
				display_name = terminal.label
			else
				local buf_name = vim.api.nvim_buf_get_name(terminal.buffer)
				display_name = buf_name ~= "" and vim.fn.fnamemodify(buf_name, ":t") or ("Terminal " .. terminal.buffer)
			end

			-- Should now use Terminal X format
			assert.matches("Terminal %d+", display_name)

			-- Clean up
			if vim.api.nvim_buf_is_valid(mock_buf) then
				vim.api.nvim_buf_delete(mock_buf, { force = true })
			end
		end)
	end)

	describe("integration with terminal state", function()
		it("correctly manages multiple terminals with different labels", function()
			-- Create multiple terminals
			local buf1 = vim.api.nvim_create_buf(false, true)
			local buf2 = vim.api.nvim_create_buf(false, true)
			local buf3 = vim.api.nvim_create_buf(false, true)

			vim.api.nvim_buf_set_name(buf1, "/path/to/file1.lua")
			vim.api.nvim_buf_set_name(buf2, "/path/to/file2.lua")
			vim.api.nvim_buf_set_name(buf3, "/path/to/file3.lua")

			-- Add to state
			state.dispatch("add_terminal", buf1, vim.fs.basename(vim.o.shell))
			state.dispatch("add_terminal", buf2, vim.fs.basename(vim.o.shell))
			state.dispatch("add_terminal", buf3, vim.fs.basename(vim.o.shell))

			-- Set custom labels for some
			state.dispatch("set_terminal_label", buf1, "Frontend Dev")
			state.dispatch("set_terminal_label", buf3, "Backend API")

			-- Verify labels
			local _, buf1label = state.terminal_label(buf1)
			local _, buf2label = state.terminal_label(buf2)
			local _, buf3label = state.terminal_label(buf3)
			assert.equals("Frontend Dev", buf1label)
			assert.equals(vim.fs.basename(vim.o.shell), buf2label) -- Default shell basename
			assert.equals("Backend API", buf3label)

			-- Verify we have 3 terminals
			local terminals = state.terminals()
			assert.equals(3, #terminals)

			-- Clean up
			for _, buf in ipairs({ buf1, buf2, buf3 }) do
				if vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_delete(buf, { force = true })
				end
			end
		end)

		it("handles terminal removal correctly with custom labels", function()
			-- Create terminals
			local buf1 = vim.api.nvim_create_buf(false, true)
			local buf2 = vim.api.nvim_create_buf(false, true)

			state.dispatch("add_terminal", buf1, vim.fs.basename(vim.o.shell))
			state.dispatch("add_terminal", buf2, vim.fs.basename(vim.o.shell))

			-- Set custom labels
			state.dispatch("set_terminal_label", buf1, "Terminal One")
			state.dispatch("set_terminal_label", buf2, "Terminal Two")

			-- Verify both exist
			assert.equals(2, #state.terminals())

			local _, buf1label = state.terminal_label(buf1)
			local _, buf2label = state.terminal_label(buf2)
			assert.equals("Terminal One", buf1label)
			assert.equals("Terminal Two", buf2label)

			-- Remove one terminal
			state.dispatch("remove_terminal", buf1)

			-- Verify only one remains
			assert.equals(1, #state.terminals())
			local buf1valid, _ = state.terminal_label(buf1)
			_, buf2label = state.terminal_label(buf2)
			assert.is_false(buf1valid) -- Should be gone
			assert.equals("Terminal Two", buf2label) -- Should remain

			-- Clean up
			for _, buf in ipairs({ buf1, buf2 }) do
				if vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_delete(buf, { force = true })
				end
			end
		end)
	end)
end)
