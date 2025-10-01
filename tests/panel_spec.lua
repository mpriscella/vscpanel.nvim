local assert = require("luassert")
local stub = require("luassert.stub")
local notify_stub

describe("vscpanel.nvim panels", function()
	before_each(function()
		require("utils").cleanup()
		notify_stub = stub(vim, "notify")
	end)

	after_each(function()
		notify_stub:revert()
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
		assert
			.stub(notify_stub)
			.was_called_with("vscpanel.nvim: Cannot toggle panel size when panel is not open", vim.log.levels.INFO)
	end)
end)
