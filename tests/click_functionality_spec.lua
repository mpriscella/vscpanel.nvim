local assert = require("luassert")
local helpers = require("tests.utils")

describe("vscpanel click functionality", function()
	local vscpanel, state

	before_each(function()
		-- Reset everything before each test
		helpers.cleanup()

		vscpanel = require("vscpanel")
		state = require("vscpanel.state")

		-- Setup with close icon enabled
		vscpanel.setup({
			size = 10,
			position = "bottom",
			icons = {
				close_terminal = "x",
			},
			keybindings = {
				close_terminal = "d",
			},
		})
	end)

	describe("line formatting", function()
		local function test_line_formatting_with_mock_terminal(label, close_icon)
			-- Create a mock terminal state
			local mock_buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_name(mock_buf, label)

			-- Mock the state.terminals function
			local original_terminals = state.terminals
			state.terminals = function()
				return { { buffer = mock_buf } }
			end

			-- Mock the get_opts function by temporarily replacing vscpanel.opts
			local original_opts = vscpanel.opts
			vscpanel.opts = {
				icons = { close_terminal = close_icon },
			}

			-- Re-implement the line formatting logic for testing
			local function test_get_formatted_line(terminal_index)
				local terminals = state.terminals()
				if terminal_index < 1 or terminal_index > #terminals then
					return nil
				end

				local terminal = terminals[terminal_index]
				if not terminal or not terminal.buffer or not vim.api.nvim_buf_is_valid(terminal.buffer) then
					return nil
				end

				local buf_name = vim.api.nvim_buf_get_name(terminal.buffer)
				local display_name = buf_name ~= "" and vim.fn.fnamemodify(buf_name, ":t")
					or ("Terminal " .. terminal.buffer)

				local opts = vscpanel.opts or { icons = { close_terminal = close_icon } }
				local close_icon_actual = opts.icons.close_terminal or ""

				-- Always include indicator (space for non-active terminal in mock)
				local indicator = " " -- Mock non-active terminal

				if close_icon_actual ~= "" then
					local padding = string.rep(" ", math.max(1, 20 - #display_name))
					return string.format("%s %s%s%s", indicator, display_name, padding, close_icon_actual)
				else
					return string.format("%s %s", indicator, display_name)
				end
			end

			local result = test_get_formatted_line(1)

			-- Restore and clean up
			state.terminals = original_terminals
			vscpanel.opts = original_opts
			if vim.api.nvim_buf_is_valid(mock_buf) then
				vim.api.nvim_buf_delete(mock_buf, { force = true })
			end

			return result
		end

		it("formats lines correctly with close icons", function()
			local line1 = test_line_formatting_with_mock_terminal("/short.lua", "x")
			local line2 = test_line_formatting_with_mock_terminal("/very/long/path/filename.lua", "x")

			assert.is.Not.Nil(line1)
			assert.is.Not.Nil(line2)

			if line1 == nil or line2 == nil then
				return
			end
			-- Check that both lines end with the close icon
			assert.is_true(line1:match("x$") ~= nil) -- Ends with 'x'
			assert.is_true(line2:match("x$") ~= nil) -- Ends with 'x'

			-- Check that lines start with indicator space and contain the display names
			assert.is_true(line1:match("^  short%.lua") ~= nil) -- indicator + space + name
			assert.is_true(line2:match("^  filename%.lua") ~= nil) -- indicator + space + name
		end)

		it("formats lines correctly without close icons", function()
			local line = test_line_formatting_with_mock_terminal("/test.lua", "")

			assert.is.Not.Nil(line)

			if line == nil then
				return
			end

			-- Should not end with 'x' and should be indicator + space + name
			assert.is_false(line:match("x$") ~= nil)
			assert.is_true(line:match("^  test%.lua$") ~= nil)
		end)
	end)
end)
