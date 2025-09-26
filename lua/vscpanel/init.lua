local M = {}

--- Setup function.
--- @param opts vscpanel.Config Configuration options.
function M.setup(opts)
	M.opts = require("vscpanel.config").normalize(opts)
end

--- Ensure the given window (or current) is a terminal and enter insert mode reliably
--- @param win integer|nil
function M.ensure_insert(win)
	win = win or vim.api.nvim_get_current_win()
	if not (win and vim.api.nvim_win_is_valid(win)) then
		return
	end

	local buf = vim.api.nvim_win_get_buf(win)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	if vim.bo[buf].buftype ~= "terminal" then
		return
	end

	if vim.api.nvim_get_current_win() == win then
		vim.cmd("startinsert")
	end
end

--- Show help window with all plugin keybindings
function M.show_help()
	require("vscpanel.help").show_help()
end

local function open_view(view)
	local state = require("vscpanel.state")
	state.dispatch("set_active_view", view)

	require("vscpanel.panel").open()
end

function M.open_terminal_view()
	open_view(require("vscpanel.views").views.TERMINAL)
end

--- INFO: This functionality is not enabled yet.
function M.open_problems_view()
	open_view(require("vscpanel.views").views.PROBLEMS)
end

function M.max_toggle()
	require("vscpanel.panel").max_toggle()
end

return M
