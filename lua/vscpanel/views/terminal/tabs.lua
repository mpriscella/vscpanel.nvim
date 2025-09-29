local M = {}
local HL_NS = vim.api.nvim_create_namespace("VSCPanelTabs")

--- Get the current configuration from the main module.
--- @return vscpanel.Config opts
local function get_opts()
	local vscpanel = require("vscpanel")
	local config = require("vscpanel.config")

	return vscpanel.opts or config.defaults
end

--- Get the state handler.
--- @return table
local function get_state()
	local state = require("vscpanel.state")
	return state
end

--- Show terminal tabs.
--- When tabs are displayed, the following key mappings are available:
--- - <Enter>: Switch to the terminal under the cursor
--- - <LeftMouse>: Click to switch to a terminal
function M.show_tabs()
	local state = get_state()
	local terminal = require("vscpanel.views.terminal")

	local window_id = state.window_id()
	if not (window_id and vim.api.nvim_win_is_valid(window_id)) then
		return
	end

	-- Save current window and mode for restoration
	local current_win = vim.api.nvim_get_current_win()
	local current_mode = vim.api.nvim_get_mode().mode

	-- Close existing terminal list if it's open
	local tabs_window = state.tabs_window()
	if tabs_window and vim.api.nvim_win_is_valid(tabs_window) then
		pcall(vim.api.nvim_win_close, tabs_window, true)
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local lines = M.generate_tabs_content()

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Add syntax highlighting for active terminal indicator
	local active_terminal = state.active_terminal()
	local terminals = state.terminals()
	local active_line = 1 -- Default to first line
	for i, t in ipairs(terminals) do
		if t.buffer and vim.api.nvim_buf_is_valid(t.buffer) then
			local is_active = (active_terminal and t.buffer == active_terminal.buffer)
			if is_active then
				-- Highlight the blue indicator
				vim.api.nvim_buf_add_highlight(buf, -1, "DiagnosticInfo", i - 1, 0, 1)
				-- Remember the line for cursor positioning
				active_line = i
			end
		end
	end

	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buftype = "nofile"

	-- Set current window to the panel window, then create vertical split
	if not vim.api.nvim_win_is_valid(window_id) then
		return
	end
	vim.api.nvim_set_current_win(window_id)
	vim.cmd("rightbelow vsplit")
	local new_win = vim.api.nvim_get_current_win()

	-- Calculate appropriate width based on content
	local width = math.max(
		25, -- Minimum width
		vim.fn.max(vim.tbl_map(function(line)
			return #line
		end, lines)) + 2 -- Add padding
	)
	vim.api.nvim_win_set_width(new_win, width)

	vim.api.nvim_win_set_buf(new_win, buf)

	-- Position cursor on the active terminal line
	vim.api.nvim_win_set_cursor(new_win, { active_line, 0 })

	-- Configure window appearance
	vim.wo[new_win].number = false
	vim.wo[new_win].relativenumber = false
	vim.wo[new_win].signcolumn = "no"
	vim.wo[new_win].foldcolumn = "0"
	vim.wo[new_win].wrap = false
	vim.wo[new_win].cursorline = true

	-- Set up key mappings for terminal selection
	local function setup_keymaps()
		-- Enter key to select terminal
		vim.keymap.set("n", "<CR>", function()
			local line_num = vim.api.nvim_win_get_cursor(new_win)[1]
			terminal.switch_to_terminal(line_num)
		end, { buffer = buf, silent = true, desc = "Switch to selected terminal" })

		-- Mouse click to select or close terminal
		vim.keymap.set("n", "<LeftMouse>", function()
			-- Get mouse position
			local mouse_pos = vim.fn.getmousepos()
			if mouse_pos.winid == new_win then
				vim.api.nvim_win_set_cursor(new_win, { mouse_pos.line, 0 })
				terminal.switch_to_terminal(mouse_pos.line)
			end
		end, { buffer = buf, silent = true, desc = "Click to switch or close terminal" })

		-- Configurable key to close terminal
		vim.keymap.set("n", "d", function()
			local line_num = vim.api.nvim_win_get_cursor(new_win)[1]
			terminal.close_terminal(line_num)
		end, { buffer = buf, silent = true, desc = "Close selected terminal" })

		-- 'r' key to rename terminal
		vim.keymap.set("n", "r", function()
			local line_num = vim.api.nvim_win_get_cursor(new_win)[1]
			terminal.rename_terminal(line_num)
		end, { buffer = buf, silent = true, desc = "Rename selected terminal" })

		-- Help keybinding
		vim.keymap.set("n", "g?", function()
			require("vscpanel.help").show_help()
		end, { buffer = buf, silent = true, desc = "Show Panel Terminal Help" })
	end

	setup_keymaps()

	-- Store references for refreshing
	state.dispatch("set_tabs_window_buffer", new_win, buf)

	-- Set up autocmd to clean up state when window is closed
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(new_win),
		callback = function()
			state.dispatch("set_tabs_window_buffer", nil, nil)
		end,
		once = true,
	})

	-- Restore focus to the original window
	vim.api.nvim_set_current_win(current_win)

	-- Restore the original mode if it was insert or visual
	if current_mode == "i" then
		vim.cmd("startinsert")
	elseif current_mode == "v" or current_mode == "V" or current_mode == "\22" then -- \22 is visual block mode
		vim.cmd("normal! gv")
	end
end

--- Refresh the terminal list in the existing buffer.
--- @return boolean: true if refresh was successful, false if no terminal list is open
function M.refresh_tabs()
	local state = require("vscpanel.state")
	local terminals = state.terminals()

	-- If ≤1 terminal, ensure tabs are closed.
	if #terminals <= 1 then
		if M.are_open() then
			M.close()
		end
		return false
	end

	-- If tabs window/buffer not present, create them and stop (show_tabs already renders content)
	if not M.are_open() then
		M.show_tabs()
		return true
	end

	local tabs_window = state.tabs_window()
	local tabs_buffer = state.tabs_buffer()
	if not (tabs_window and vim.api.nvim_win_is_valid(tabs_window)) then
		return false
	end
	if not (tabs_buffer and vim.api.nvim_buf_is_valid(tabs_buffer)) then
		return false
	end

	local lines = M.generate_tabs_content()

	-- Make buffer modifiable temporarily; handle races with a retry.
	local function set_lines_safe()
		if not vim.api.nvim_buf_is_valid(tabs_buffer) then
			return false
		end
		local prev_mod = vim.bo[tabs_buffer].modifiable
		if not prev_mod then
			vim.bo[tabs_buffer].modifiable = true
		end
		local ok = pcall(vim.api.nvim_buf_set_lines, tabs_buffer, 0, -1, false, lines)
		-- Restore modifiable to false (tabs buffer is read-only UI)
		if vim.api.nvim_buf_is_valid(tabs_buffer) then
			vim.bo[tabs_buffer].modifiable = false
		end
		return ok
	end

	local ok = set_lines_safe()
	if not ok then
		-- Schedule one retry in case of transient race
		vim.schedule(function()
			if M.are_open() then
				set_lines_safe()
			end
		end)
	end

	-- Highlights: clear previous namespace then add current active indicator
	if vim.api.nvim_buf_is_valid(tabs_buffer) then
		vim.api.nvim_buf_clear_namespace(tabs_buffer, HL_NS, 0, -1)
		local active_terminal = state.active_terminal()
		local active_line = 1
		for i, terminal in ipairs(terminals) do
			if terminal.buffer and vim.api.nvim_buf_is_valid(terminal.buffer) then
				if active_terminal and terminal.buffer == active_terminal.buffer then
					vim.api.nvim_buf_add_highlight(tabs_buffer, HL_NS, "DiagnosticInfo", i - 1, 0, 1)
					active_line = i
				end
			end
		end
		if tabs_window and vim.api.nvim_win_is_valid(tabs_window) then
			pcall(vim.api.nvim_win_set_cursor, tabs_window, { active_line, 0 })
		end
	end

	-- Adjust width after content update
	if tabs_window and vim.api.nvim_win_is_valid(tabs_window) then
		local width = math.max(25, vim.fn.max(vim.tbl_map(function(line)
			return #line
		end, lines)) + 2)
		pcall(vim.api.nvim_win_set_width, tabs_window, width)
	end

	return true
end

--- Closes the terminal tabs.
function M.close()
	local state = require("vscpanel.state")

	local tabs_window = state.tabs_window()
	local tabs_buffer = state.tabs_buffer()

	if tabs_buffer and vim.api.nvim_buf_is_valid(tabs_buffer) then
		pcall(vim.api.nvim_buf_delete, tabs_buffer, { force = true })
	end
	if tabs_window and vim.api.nvim_win_is_valid(tabs_window) then
		pcall(vim.api.nvim_win_close, tabs_window, true)
	end

	state.dispatch("set_tabs_window_buffer", nil, nil)
	return true
end

--- Generate terminal list lines for display
--- @return table: Array of formatted terminal lines
function M.generate_tabs_content()
	local state = get_state()
	local terminals = state.terminals()
	local lines = {}
	local active_terminal = state.active_terminal()

	-- Convert terminal objects to displayable strings
	for i, terminal in ipairs(terminals) do
		if terminal.buffer and vim.api.nvim_buf_is_valid(terminal.buffer) then
			-- Use custom label if set, otherwise fall back to buffer name or default
			local display_name
			if terminal.label and terminal.label ~= "" then
				display_name = terminal.label
			else
				local buf_name = vim.api.nvim_buf_get_name(terminal.buffer)
				display_name = buf_name ~= "" and vim.fn.fnamemodify(buf_name, ":t") or ("Terminal " .. terminal.buffer)
			end

			-- Check if this is the active terminal
			local is_active = (active_terminal and terminal.buffer == active_terminal.buffer)
			local indicator = is_active and "│" or " "

			-- Add close icon with right justification
			local opts = get_opts()
			local close_icon = opts.icons.terminal.close_terminal or ""
			if close_icon ~= "" then
				local padding = string.rep(" ", math.max(1, 20 - #display_name))
				lines[i] = string.format("%s  %s%s%s", indicator, display_name, padding, close_icon)
			else
				lines[i] = string.format("%s  %s", indicator, display_name)
			end
		else
			lines[i] = string.format("%d: Invalid terminal", i)
		end
	end

	-- If no terminals, show a message
	if #lines == 0 then
		lines[1] = "No terminals found"
	end

	return lines
end

--- Check if the terminal tab window is currently open
--- @return boolean: Whether the terminal tab window is open and valid.
function M.are_open()
	local state = get_state()
	local tabs_window = state.tabs_window()
	local tabs_buffer = state.tabs_buffer()

	return not not (
		tabs_window
		and vim.api.nvim_win_is_valid(tabs_window)
		and tabs_buffer
		and vim.api.nvim_buf_is_valid(tabs_buffer)
	)
end

--- Hide tabs and remember they were open for when panel reopens.
--- @return boolean: true if operation was successful
function M.hide()
	local state = get_state()

	if M.are_open() then
		local tabs_window = state.tabs_window()
		if tabs_window and vim.api.nvim_win_is_valid(tabs_window) then
			pcall(vim.api.nvim_win_close, tabs_window, true)
		end
		state.dispatch("set_tabs_window_buffer", nil, nil)
	end
	return true
end

return M
