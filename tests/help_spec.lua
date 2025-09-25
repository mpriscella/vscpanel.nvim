local assert = require("luassert")

describe("vscpanel help functionality", function()
	after_each(require("utils").cleanup)

	describe("help window functionality", function()
		it("has show_help function in help module", function()
			local help = require("vscpanel.help")
			assert.is_function(help.show_help)
		end)

		it("has show_help function in main module", function()
			local vscpanel = require("vscpanel")
			assert.is_function(vscpanel.show_help)
		end)

		it("registers PanelTermHelp command", function()
			require("vscpanel.commands").register()

			-- Check if the command exists
			local commands = vim.api.nvim_get_commands({})
			assert.is.Not.Nil(commands.PanelTermHelp)
			assert.equals("Show Panel Terminal Help", commands.PanelTermHelp.definition)
		end)
	end)
end)
