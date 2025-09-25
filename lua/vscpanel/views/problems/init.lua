local M = {}

--- INFO: This functionality is not enabled yet.

-- Should use vim.diagnostic.setloclist to get quickfix list

local function get_state()
	local state = require("vscpanel.state")
	return state
end

--- Create view
function M.open()
	local state = get_state()
	-- Create buffer.
	local buf = vim.api.nvim_create_buf(false, true)
	local win_id = state.window_id()
	vim.api.nvim_win_set_buf(win_id, buf)
	-- Set buffer to view window.
	--   Might need to track windows per view in a generic way.
end

function M.setup()
	vim.api.nvim_create_autocmd({ "WinEnter" }, {
		callback = function()
			local state = get_state()
			local panel_win = state.window_id()
			if not (panel_win and vim.api.nvim_win_is_valid(panel_win)) then
				return
			end

			-- Window that just became current
			local active_win = vim.api.nvim_get_current_win()
			if not vim.api.nvim_win_is_valid(active_win) then
				return
			end

			if active_win == panel_win then
				return
			end

			-- Populate loclist for the active window
			vim.diagnostic.setloclist({ winnr = active_win })

			-- Read loclist items from the active window
			local ok, info = pcall(vim.fn.getloclist, active_win, { items = 1 })
			local items = (ok and info and info.items) or {}

			-- Destination buffer: panel window's buffer
			local panel_buf = vim.api.nvim_win_get_buf(panel_win)
			if not vim.api.nvim_buf_is_valid(panel_buf) then
				return
			end

			local lines = {}
			for _, it in ipairs(items) do
				local fname = (it.bufnr and vim.api.nvim_buf_is_valid(it.bufnr)) and vim.api.nvim_buf_get_name(it.bufnr)
					or ""
				local lnum = it.lnum or 0
				local col = it.col or 0
				local text = it.text or ""
				local typech = it.type or ""
				table.insert(lines, string.format("%s:%d:%d: %s %s", fname, lnum, col, typech, text))
			end

			if #lines == 0 then
				lines = { "-- no diagnostics --" }
			end

			vim.api.nvim_buf_set_lines(panel_buf, 0, -1, false, lines)
		end,
	})
end

return M
