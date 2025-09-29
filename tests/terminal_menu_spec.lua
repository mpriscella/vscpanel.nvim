local assert = require("luassert")
local helpers = require("tests.utils")

describe("vscpanel shell picker menu functionality", function()
	local vscpanel

	before_each(function()
		-- Reset everything before each test
		helpers.cleanup()

		vscpanel = require("vscpanel")

		-- Setup with shell picker menu functionality enabled
		vscpanel.setup({
			size = 10,
			position = "bottom",
			icons = {
				close_terminal = "x",
			},
		})
	end)

	describe("command registration", function()
		it("registers ShowTerminalMenu command", function()
			require("vscpanel.commands").register()
			-- Check if the command exists
			local commands = vim.api.nvim_get_commands({})
			assert.is.Not.Nil(commands.ShowTerminalMenu)
			assert.equals("Show Terminal Menu", commands.ShowTerminalMenu.definition)
		end)
	end)

	describe("menu functionality", function()
		it("menu module has toggle function", function()
			local menu = require("vscpanel.views.terminal.context_menu")
			assert.is_function(menu.toggle)
		end)
	end)
end)
