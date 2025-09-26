local assert = require("luassert")

describe("vscpanel max_toggle", function()
	after_each(require("utils").cleanup)

	it("continues working after panel has been closed", function()
		local M = require("vscpanel")
		M.setup({}) -- Add setup call to initialize winbar
		local panel = require("vscpanel.panel")

		panel.toggle_panel() -- Panel open.
		panel.toggle_panel() -- Panel close.
		panel.toggle_panel() -- Panel open.

		local win = vim.api.nvim_get_current_win()

		-- If we have a proper terminal, test the full maximize/minimize cycle
		local winbar = vim.api.nvim_get_option_value("winbar", { win = win })
		assert.is_truthy(winbar:find(" ", 1, true))

		-- Maximize
		M.max_toggle()

		local current_win = vim.api.nvim_get_current_win()
		local current_buf = vim.api.nvim_win_get_buf(current_win)

		if vim.bo[current_buf].buftype == "terminal" then
			winbar = vim.api.nvim_get_option_value("winbar", { win = current_win })
			assert.is_truthy(winbar:find(" ", 1, true))

			-- Minimize / restore
			M.max_toggle()
			current_win = vim.api.nvim_get_current_win()
			winbar = vim.api.nvim_get_option_value("winbar", { win = current_win })
			assert.is_truthy(winbar:find(" ", 1, true))
		end
	end)
end)
