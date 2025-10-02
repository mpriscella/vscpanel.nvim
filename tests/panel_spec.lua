local assert = require("luassert")
local stub = require("luassert.stub")

local info_stub
local logging

describe("vscpanel.nvim panels", function()
	before_each(function()
		logging = require("vscpanel.logging")
		info_stub = stub(logging, "info")
	end)

	after_each(function()
		require("utils").cleanup()
		info_stub:revert()
	end)

	it("creates a panel window", function()
		require("vscpanel").setup({})
		local panel = require("vscpanel.panel")
		local state = require("vscpanel.state")
		local config = require("vscpanel.config")

		panel.create_panel({})

		local win = vim.api.nvim_get_current_win()
		local height = vim.api.nvim_win_get_height(win)
		assert.are.equal(height, config.defaults.size)
		assert.are.equal(win, state.window_id())
	end)

	it("doesn't toggle size when panel is not open", function()
		local panel = require("vscpanel.panel")
		panel.create_panel({})
		panel.toggle_panel()

		panel.max_toggle()
		assert.stub(info_stub).was_called_with("vscpanel.nvim: Cannot toggle panel size when panel is not open")
	end)
end)
