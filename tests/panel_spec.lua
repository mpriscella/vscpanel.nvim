local assert = require("luassert")

describe("vscpanel.nvim panels", function()
	after_each(require("utils").cleanup)

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
end)
