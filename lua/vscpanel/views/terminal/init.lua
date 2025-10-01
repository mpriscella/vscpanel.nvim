local M = {}

--- Get the current configuration from the main module.
--- @return vscpanel.Config opts
local function get_opts()
	local vscpanel = require("vscpanel")
	local config = require("vscpanel.config")

	return vscpanel.opts or config.defaults
end

--- Setup terminal functionality.
function M.setup()
	local constants = require("vscpanel.constants")
	local aug = vim.api.nvim_create_augroup(constants.AUGROUP_NAME, { clear = true })

	vim.api.nvim_create_autocmd("TermClose", {
		group = aug,
		callback = function(args)
			local buf = args.buf
			if not (buf and vim.api.nvim_buf_is_valid(buf)) then
				return
			end

			M.handle_terminal_removal(buf)
		end,
		desc = "Clean up vscpanel terminal on close",
	})
end

--- Creates a terminal and sets it as the active terminal.
--- @param win number The window to open the terminal buffer in.
--- @param shell string|nil The shell command.
--- @return number buffer_id The buffer ID of the new terminal session.
function M.create_terminal(win, shell)
	-- require("vscpanel.views.terminal").setup()
	local opts = get_opts()
	local cmd = shell or opts.shell

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(win, buf)

	local ok = false
	local chan

	vim.api.nvim_buf_call(buf, function()
		chan = vim.fn.jobstart(cmd, { term = true })
		ok = type(chan) == "number" and chan > 0
	end)

	if ok then
		local state = require("vscpanel.state")
		state.dispatch("add_terminal", { buffer = buf, label = vim.fs.basename(cmd), shell = cmd })
		state.dispatch("set_active_terminal", buf)

		require("vscpanel.keybinds").setup_terminal_keybinds(buf)
		require("vscpanel.views.terminal.tabs").refresh_tabs()
		vim.api.nvim_exec_autocmds("User", {
			pattern = "WinbarUpdate",
		})

		vim.api.nvim_create_autocmd("TermClose", {
			buffer = buf,
			callback = function(args)
				if not (args.buf and vim.api.nvim_buf_is_valid(args.buf)) then
					return
				end

				M.handle_terminal_removal(args.buf)
			end,
			desc = "Clean up vscpanel terminal on close",
		})
	else
		vim.notify("vscpanel.nvim: Failed to start " .. cmd .. " terminal", vim.log.levels.ERROR)
	end

	return buf
end

--- Close a terminal by line number
--- @param line_number integer: The line number in the terminal list (1-based)
function M.close_terminal(line_number)
	local state = require("vscpanel.state")
	local terminals = state.terminals()

	-- Validate line number
	if line_number < 1 or line_number > #terminals then
		return
	end

	local terminal_to_close = terminals[line_number]
	if terminal_to_close and terminal_to_close.buffer then
		local buffer_to_close = terminal_to_close.buffer

		-- Adjust active terminal if necessary before closing
		local active = state.active_terminal()
		if active.buffer == buffer_to_close then
			-- Set active to the first available terminal that's not the one being closed
			local remaining_terminals = state.terminals()
			local new_active_terminal = nil
			for _, term in ipairs(remaining_terminals) do
				if term.buffer ~= buffer_to_close then
					new_active_terminal = term.buffer
					break
				end
			end

			if new_active_terminal then
				state.dispatch("set_active_terminal", new_active_terminal)
				-- Switch the panel to the new active terminal
				local panel_window = state.window_id()
				if panel_window and vim.api.nvim_win_is_valid(panel_window) then
					vim.api.nvim_win_set_buf(panel_window, new_active_terminal)

					-- Set up buffer-local keybinds for the new active terminal
					require("vscpanel.keybinds").setup_terminal_keybinds(new_active_terminal)

					-- Focus the main panel window
					vim.api.nvim_set_current_win(panel_window)

					-- Enter insert mode in the terminal
					require("vscpanel").ensure_insert(panel_window)
				end
			else
				state.dispatch("set_active_terminal", nil)
			end
		else
			-- Deleting a non-active terminal, ensure user is back in insert mode in the active terminal
			local panel_window = state.window_id()
			if panel_window and vim.api.nvim_win_is_valid(panel_window) then
				-- Focus the main panel window
				vim.api.nvim_set_current_win(panel_window)

				-- Enter insert mode in the terminal
				require("vscpanel").ensure_insert(panel_window)
			end
		end

		-- Force delete the terminal buffer (this will trigger TermClose autocmd which handles state cleanup)
		if vim.api.nvim_buf_is_valid(buffer_to_close) then
			vim.api.nvim_buf_delete(buffer_to_close, { force = true })
		end
	end
end

--- Rename a terminal
--- @param line_number integer: Line number of the terminal to rename
function M.rename_terminal(line_number)
	local state = require("vscpanel.state")
	local terminals = state.terminals()
	local tabs = require("vscpanel.views.terminal.tabs")

	if line_number < 1 or line_number > #terminals then
		vim.notify("vscpanel.nvim: Invalid terminal selection", vim.log.levels.WARN)
		return
	end

	local terminal = terminals[line_number]
	if not terminal or not terminal.buffer or not vim.api.nvim_buf_is_valid(terminal.buffer) then
		vim.notify("vscpanel.nvim: Invalid terminal", vim.log.levels.WARN)
		return
	end

	-- Get current label
	local current_label = terminal.label or ""

	-- Prompt for new label
	vim.ui.input({
		prompt = "Rename terminal: ",
		default = current_label,
	}, function(new_label)
		if new_label then
			-- Update the terminal label
			state.dispatch("set_terminal_label", terminal.buffer, new_label)
			-- state.set_terminal_label(terminal.buffer, new_label)
			-- Refresh the terminal list display
			tabs.refresh_tabs()
			vim.notify("vscpanel.nvim: Terminal renamed to: " .. new_label, vim.log.levels.INFO)
		end
	end)
end

--- Switch to a specific terminal by line number in the tab list
--- @param line_number integer: The line number in the terminal list (1-based)
function M.switch_to_terminal(line_number)
	local state = require("vscpanel.state")
	local terminals = state.terminals()
	local tabs = require("vscpanel.views.terminal.tabs")

	-- Validate line number
	if line_number < 1 or line_number > #terminals then
		return
	end

	local selected_terminal = terminals[line_number]
	if not selected_terminal or not selected_terminal.buffer then
		return
	end

	-- Check if the buffer is still valid
	if not vim.api.nvim_buf_is_valid(selected_terminal.buffer) then
		return
	end

	-- Get the main panel window
	local panel_window = state.window_id()
	if not panel_window or not vim.api.nvim_win_is_valid(panel_window) then
		return
	end

	-- Switch the buffer in the main panel
	vim.api.nvim_win_set_buf(panel_window, selected_terminal.buffer)

	-- Update the active terminal in state
	state.dispatch("set_active_terminal", selected_terminal.buffer)

	-- Set up buffer-local keybinds for the switched terminal
	require("vscpanel.keybinds").setup_terminal_keybinds(selected_terminal.buffer)

	-- Focus the main panel window
	vim.api.nvim_set_current_win(panel_window)

	-- Enter insert mode in the terminal
	require("vscpanel").ensure_insert(panel_window)

	-- Refresh terminal tabs to update active indicator
	tabs.refresh_tabs()
end

--- Handle terminal removal and auto-hide tabs if needed
--- @param buffer_id integer: Buffer ID of the terminal being removed
function M.handle_terminal_removal(buffer_id)
	local state = require("vscpanel.state")
	local tabs = require("vscpanel.views.terminal.tabs")

	-- Determine if the closed buffer was the active terminal
	local was_active = state.active_terminal().buffer == buffer_id

	-- Remove terminal from state
	state.dispatch("remove_terminal", buffer_id)

	-- Get remaining terminals count
	local terminals = state.terminals()

	-- If the closed terminal was active, switch the panel window to the new active terminal
	if was_active and #terminals > 0 then
		local new_active = state.active_terminal()
		-- Fallback in case active_terminal wasn't set by remove_terminal for some reason
		if not (new_active and vim.api.nvim_buf_is_valid(new_active.buffer)) then
			new_active = terminals[1] and terminals[1] or nil
			if new_active then
				state.dispatch("set_active_terminal", new_active.buffer)
			end
		end

		local panel_window = state.window_id()
		if
			panel_window
			and vim.api.nvim_win_is_valid(panel_window)
			and new_active
			and vim.api.nvim_buf_is_valid(new_active.buffer)
		then
			-- Switch displayed buffer to the new active terminal
			vim.api.nvim_win_set_buf(panel_window, new_active.buffer)

			-- Re-apply terminal keybinds for the new buffer
			require("vscpanel.keybinds").setup_terminal_keybinds(new_active.buffer)

			-- Ensure focus and insert mode stay in the panel
			vim.api.nvim_set_current_win(panel_window)
			require("vscpanel").ensure_insert(panel_window)

			-- Update winbar indicators
			vim.api.nvim_exec_autocmds("User", { pattern = "WinbarUpdate" })
		end
	end

	-- If there are no terminals left, close the panel entirely
	if #terminals == 0 then
		-- If the closed buffer is still displayed in the panel window, clear it first
		local panel_window = state.window_id()
		if panel_window and vim.api.nvim_win_is_valid(panel_window) then
			local ok_buf, cur = pcall(vim.api.nvim_win_get_buf, panel_window)
			if ok_buf and cur == buffer_id then
				-- Switch to a scratch buffer to allow deletion without E937
				local scratch = vim.api.nvim_create_buf(false, true)
				vim.api.nvim_win_set_buf(panel_window, scratch)
			end
		end

		require("vscpanel.panel").close_panel()
		-- Clear active terminal explicitly
		state.dispatch("set_active_terminal", nil)
		-- Delete the closed buffer on next tick if it still exists
		if buffer_id then
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(buffer_id) then
					-- Ensure no window is showing this buffer
					local in_use = false
					for _, w in ipairs(vim.api.nvim_list_wins()) do
						local ok, b = pcall(vim.api.nvim_win_get_buf, w)
						if ok and b == buffer_id then
							in_use = true
							break
						end
					end
					if not in_use then
						pcall(vim.api.nvim_buf_delete, buffer_id, { force = true })
					end
				end
			end)
		end
		return
	end

	tabs.refresh_tabs()

	-- Ensure the closed buffer is deleted on next tick if it still exists and is not displayed
	if buffer_id then
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(buffer_id) then
				local in_use = false
				for _, w in ipairs(vim.api.nvim_list_wins()) do
					local ok, b = pcall(vim.api.nvim_win_get_buf, w)
					if ok and b == buffer_id then
						in_use = true
						break
					end
				end
				if not in_use then
					pcall(vim.api.nvim_buf_delete, buffer_id, { force = true })
				end
			end
		end)
	end
end

return M
