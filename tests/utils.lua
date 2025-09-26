local M = {}

--- Cleanup function to reset state between tests.
function M.cleanup()
	local constants = require("vscpanel.constants")
	pcall(function()
		require("vscpanel.panel").close_panel()
	end)

	-- Reset module cache to ensure clean state.
	package.loaded["vscpanel"] = nil
	package.loaded["vscpanel.commands"] = nil
	package.loaded["vscpanel.config"] = nil
	package.loaded["vscpanel.health"] = nil
	package.loaded["vscpanel.help"] = nil
	package.loaded["vscpanel.keybinds"] = nil
	package.loaded["vscpanel.panel"] = nil
	package.loaded["vscpanel.state"] = nil
	package.loaded["vscpanel.winbar"] = nil
	package.loaded["vscpanel.views.problems"] = nil
	package.loaded["vscpanel.views.terminal"] = nil
	package.loaded["vscpanel.views.terminal.context_menu"] = nil
	package.loaded["vscpanel.views.terminal.tabs"] = nil

	-- TODO: Should iterate over terminals and delete them if they exist.

	-- TODO: A hardcoded string shouldn't be passed in. Instead the autocmd group
	-- name should be pulled from a shared location, like config or something.
	--
	-- Clear any autocmds
	pcall(vim.api.nvim_del_augroup_by_name, constants.AUGROUP_NAME)
end

return M
