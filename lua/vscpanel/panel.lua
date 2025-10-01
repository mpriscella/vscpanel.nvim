local M = {}

--- Get the current configuration from the main module
--- @return vscpanel.Config
local function get_config()
	local vscpanel = require("vscpanel")
	local config = require("vscpanel.config")

	return vscpanel.opts or config.defaults
end

--- @class vscpanel.CreatePanelArgs
--- @field position string? The position of the panel. Either "bottom"
---   (default), "top", "left", or "right".
--- @field size number? The size of the panel when the position is "bottom" or
---   "top"

--- Creates a panel without a buffer attached.
--- @param args vscpanel.CreatePanelArgs
--- @return number win The window ID of the newly created panel.
function M.create_panel(args)
	local defaults = require("vscpanel.config").defaults
	local position = args.position or defaults.position
	local size = args.size or defaults.size

	local split_commands = {
		bottom = "bot split",
		top = "top split",
		left = "topleft vsplit",
		right = "botright vsplit",
	}

	vim.cmd(split_commands[position])
	local win = vim.api.nvim_get_current_win()

	if position == "bottom" or position == "top" then
		vim.api.nvim_win_set_height(win, size)
	end

	require("vscpanel.state").dispatch("set_window", win)
	return win
end

--- Closes the panel.
function M.close_panel()
	local state = require("vscpanel.state")
	local win = state.window_id()
	if not win then
		return
	end

	-- Hide tabs and remember their state for when panel reopens
	require("vscpanel.views.terminal.tabs").hide()

	state.dispatch("set_maximized", false)

	-- TODO: If the active terminal is set when terminals are created, this step is unnecessary.

	-- Store the current buffer before closing the window to preserve terminal state
	if vim.api.nvim_win_is_valid(win) then
		local ok_buf, current_buf = pcall(vim.api.nvim_win_get_buf, win)
		if
			ok_buf
			and current_buf
			and vim.api.nvim_buf_is_valid(current_buf)
			and vim.bo[current_buf].buftype == "terminal"
		then
			state.dispatch("set_active_terminal", current_buf)
		end
	end

	-- Actually close the window - this makes it completely invisible
	if vim.api.nvim_win_is_valid(win) then
		pcall(vim.api.nvim_win_close, win, false) -- false = don't force close, preserve buffer
	end
	state.dispatch("clear_window")
end

--- TODO: This needs to just create the panel, not the terminal.
---
--- @return number window_id
function M.open()
	require("vscpanel.winbar").setup()
	local state = require("vscpanel.state")
	local win = state.window_id()

	if win and vim.api.nvim_win_is_valid(win) then
		return win
	end

	local opts = get_config()
	local new_win = M.create_panel({ position = opts.position, size = opts.size })
	return new_win
end

--- @return boolean
function M.is_open()
	local win = require("vscpanel.state").window_id()
	if not win or not vim.api.nvim_win_is_valid(win) then
		return false
	end
	return true
end

--- Toggles the panel.
function M.toggle_panel()
	local state = require("vscpanel.state")

	if not M.is_open() then
		local new_win = M.open()

		-- Determine Active View
		local views = require("vscpanel.views")
		local active_view = views.active_view()

		-- Create View (if it doesn't already exist)
		if active_view == views.views.TERMINAL then
			local active_terminal = state.active_terminal()

			if active_terminal and vim.api.nvim_buf_is_valid(active_terminal.buffer) then
				vim.api.nvim_win_set_buf(new_win, active_terminal.buffer)
				require("vscpanel.keybinds").setup_terminal_keybinds(active_terminal.buffer)
			else
				require("vscpanel.views.terminal").create_terminal(new_win)
			end

			vim.api.nvim_exec_autocmds("User", {
				pattern = "WinbarUpdate",
			})

			-- Restore tabs if they should be shown
			require("vscpanel.views.terminal.tabs").refresh_tabs()

			require("vscpanel").ensure_insert()
		elseif active_view == views.views.PROBLEMS then
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_win_set_buf(new_win, buf)
			vim.diagnostic.setloclist({ winnr = new_win })
		end
	else
		M.close_panel()
	end
end

--- Toggle maximize for a window (current window by default, or your panel
--- window if set).
--- @param winid? integer  -- window to toggle; defaults to state.panel_win or current
function M.max_toggle(winid)
	if not M.is_open() then
		vim.notify("vscpanel.nvim: Cannot toggle panel size when panel is not open", vim.log.levels.INFO)
		return
	end

	local state = require("vscpanel.state")
	local target = winid

	if not target then
		target = state.window_id()
	end

	-- Tabpage-scoped state so each tab can have its own maximize toggle
	local key = "vscpanel_max_state"
	local tstate = vim.t[key]

	-- If we're already maximized for this target, restore the old layout
	if tstate and tstate.win == target then
		-- Guard: the saved winrestcmd might fail if windows changed radically
		pcall(vim.cmd, tstate.cmd)

		-- After restoring, the target window id may change. Prefer to find the
		-- window displaying the original buffer if we tracked it.
		local restored_win = nil
		if tstate.buf and vim.api.nvim_buf_is_valid(tstate.buf) then
			for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
				if vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_buf(w) == tstate.buf then
					restored_win = w
					break
				end
			end
		end
		if not restored_win and vim.api.nvim_win_is_valid(target) then
			restored_win = target
		end

		vim.t[key] = nil

		-- Update state and winbar, then focus and enter insert mode
		if restored_win then
			state.dispatch("set_window", restored_win)
			pcall(vim.api.nvim_set_current_win, restored_win)
			require("vscpanel").ensure_insert(restored_win)
		end
		return
	end

	-- Otherwise, maximize the target window
	local prev_win = vim.api.nvim_get_current_win()
	local restore_cmd = vim.fn.winrestcmd() -- captures the entire layout of the tabpage

	if prev_win ~= target then
		vim.api.nvim_set_current_win(target)
	end

	-- Set max width and height for this window.
	vim.cmd("wincmd |")
	vim.cmd("wincmd _")

	-- Save restore info in the tab’s state
	vim.t[key] = {
		win = target,
		cmd = restore_cmd,
		prev_win = prev_win,
		buf = vim.api.nvim_win_get_buf(target),
	}

	-- Keep our panel window tracking in sync
	state.dispatch("set_window", target)

	-- Enter insert mode when maximized (current window is target)
	if vim.api.nvim_get_current_win() == target then
		require("vscpanel").ensure_insert(target)
	end
end

return M
