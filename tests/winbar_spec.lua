local assert = require("luassert")

describe("vscpanel winbar", function()
	after_each(require("utils").cleanup)

	it("autocommand has been registered", function()
		require("vscpanel.winbar").setup()

		local autocommands = vim.api.nvim_get_autocmds({
			event = "User",
			pattern = { "WinbarUpdate" },
		})
		assert.are.Not.equal(0, #autocommands)
	end)
end)
