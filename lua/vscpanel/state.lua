local M = {}

--- @class panel.State
--- @field window_id number?
--- @field terminals panel.State.Terminal[]
--- @field active_terminal number?
--- @field maximized boolean
--- @field tabs_visible boolean
--- @field active_view number
--- @field tabs_window number?
--- @field tabs_buffer number?

--- @class panel.State.Terminal
--- @field buffer number
--- @field label string

--- @type panel.State
local state = {
	window_id = nil,
	terminals = {},
	active_terminal = nil,
	maximized = false,
	tabs_visible = false,
	active_view = require("vscpanel.views").views.TERMINAL,
	tabs_window = nil,
	tabs_buffer = nil,
}

--- A group of functions that modify state safely.
local actions = {}

--- Validates the provided Buffer ID.
--- @param buffer_id number The Buffer ID.
--- @return boolean is_valid Whether the Buffer ID is valid.
local function validate_buffer(buffer_id)
	return buffer_id and vim.api.nvim_buf_is_valid(buffer_id)
end

--- Validates the provided window ID.
--- @param window_id number The Window ID.
--- @return boolean is_valid Whether the Window ID is valid.
local function validate_window(window_id)
	return window_id and vim.api.nvim_win_is_valid(window_id)
end

--- The panels active window. Maybe it should be panel_window to match
--- tabs_window.
--- @param window_id number
--- @return boolean result
--- @return string? error_msg
actions.set_window = function(window_id)
	if not validate_window(window_id) then
		return false, "Invalid window ID"
	end

	state.window_id = window_id
	return true
end

--- @return boolean result
actions.clear_window = function()
	state.window_id = nil
	return true
end

--- @param view number
--- @return boolean result
actions.set_active_view = function(view)
	state.active_view = view
	return true
end

--- @param buffer_id number
--- @param label string
--- @return boolean result
--- @return string? error_msg
actions.add_terminal = function(buffer_id, label)
	if not validate_buffer(buffer_id) then
		return false, "Invalid buffer ID"
	end

	-- Check for duplicates
	for _, terminal in ipairs(state.terminals) do
		if terminal.buffer == buffer_id then
			return false, "Terminal already exists"
		end
	end

	--- @type panel.State.Terminal
	local new_terminal = {
		buffer = buffer_id,
		label = label or ("Terminal " .. #state.terminals + 1),
	}

	table.insert(state.terminals, new_terminal)

	return true
end

--- @return boolean result
actions.clear_terminals = function()
	state.terminals = {}
	return true
end

--- @param buffer_id number
--- @return boolean result
--- @return string? error_msg
actions.remove_terminal = function(buffer_id)
	-- Find index of terminal to remove
	local idx = nil
	for i, terminal in ipairs(state.terminals) do
		if terminal.buffer == buffer_id then
			idx = i
			break
		end
	end

	if not idx then
		return false, "Terminal not found"
	end

	-- Remove the terminal from the list first
	table.remove(state.terminals, idx)

	-- Set the new active terminal appropriately
	local count = #state.terminals
	if count == 0 then
		state.active_terminal = nil
	else
		-- Prefer previous terminal if available; otherwise, fallback to the first remaining
		local new_index = idx
		if new_index > count then
			new_index = count
		end
		if new_index < 1 then
			new_index = 1
		end
		state.active_terminal = state.terminals[new_index].buffer
	end

	return true
end

--- Sets the active terminal.
--- @param buffer_id number
--- @return boolean result
--- @return string? error_msg
actions.set_active_terminal = function(buffer_id)
	if buffer_id and not validate_buffer(buffer_id) then
		return false, "Invalid buffer ID"
	end

	state.active_terminal = buffer_id
	return true
end

--- Sets the label for a given terminal buffer.
--- @param buffer_id number
--- @param new_label string
--- @return boolean result
--- @return string? error_msg
actions.set_terminal_label = function(buffer_id, new_label)
	if not validate_buffer(buffer_id) then
		return false, "Invalid buffer ID"
	end

	for _, terminal in ipairs(state.terminals) do
		if terminal.buffer == buffer_id then
			terminal.label = new_label or ("Terminal " .. buffer_id)
			return true
		end
	end

	return false, "Terminal not found"
end

--- @return boolean result
actions.set_maximized = function(maximized)
	state.maximized = not not maximized -- convert to boolean
	return true
end

--- @return boolean result
actions.set_tabs_visible = function(visible)
	state.tabs_visible = not not visible
	return true
end

--- Set tabs window and buffer
--- @param window_id number|nil
--- @param buffer_id number|nil
--- @return boolean result
actions.set_tabs_window_buffer = function(window_id, buffer_id)
	state.tabs_window = window_id
	state.tabs_buffer = buffer_id
	return true
end

actions.cleanup_invalid = function()
	local cleaned = 0

	-- Clean invalid window
	if state.window_id and not validate_window(state.window_id) then
		state.window_id = nil
		cleaned = cleaned + 1
	end

	-- Clean invalid terminals
	local valid_terminals = {}
	for _, terminal in ipairs(state.terminals) do
		if validate_buffer(terminal.buffer) then
			table.insert(valid_terminals, terminal)
		else
			cleaned = cleaned + 1
		end
	end
	state.terminals = valid_terminals

	-- Clean invalid active terminal
	if state.active_terminal and not validate_buffer(state.active_terminal) then
		state.active_terminal = nil
		cleaned = cleaned + 1
	end

	return cleaned
end

--- Dispatch an action safely.
--- @param action_name string
--- @param ... any
--- @return boolean success
--- @return string? error_message
function M.dispatch(action_name, ...)
	local action = actions[action_name]
	if not action then
		return false, "Unknown action: " .. action_name
	end

	local ok, result, error_msg = pcall(action, ...)
	if not ok then
		return false, "Action failed: " .. result
	end

	return result, error_msg
end

--- Convenient getters

--- @return number window_id
function M.window_id()
	return state.window_id
end

--- @return panel.State.Terminal[] terminals
function M.terminals()
	return vim.deepcopy(state.terminals)
end

--- @return number active_terminal
function M.active_terminal()
	return state.active_terminal
end

--- @return boolean maximized
function M.is_maximized()
	return state.maximized
end

--- @return boolean tabs_visible
function M.tabs_visible()
	return state.tabs_visible
end

--- @return number active_view
function M.active_view()
	return state.active_view
end

--- @return number|nil tabs_window
function M.tabs_window()
	local winid = state.tabs_window
	if winid and vim.api.nvim_win_is_valid(winid) then
		return winid
	end
	return nil
end

--- @return number|nil tabs_buffer
function M.tabs_buffer()
	local buffer = state.tabs_buffer
	if buffer and vim.api.nvim_buf_is_valid(buffer) then
		return buffer
	end
	return nil
end

--- @return boolean valid
--- @return string label
function M.terminal_label(buffer_id)
	if not validate_buffer(buffer_id) then
		return false, "Invalid buffer ID"
	end

	for _, terminal in ipairs(state.terminals) do
		if terminal.buffer == buffer_id then
			return true, terminal.label
		end
	end

	return false, "Terminal not found"
end

return M
