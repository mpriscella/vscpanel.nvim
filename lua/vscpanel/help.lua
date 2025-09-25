local M = {}

--- @type number|nil This is a description.
local help_win = nil

--- @type number|nil This is a description.
local help_buf = nil

--- Closes the help menu.
local function close_help()
	if help_win and vim.api.nvim_win_is_valid(help_win) then
		pcall(vim.api.nvim_win_close, help_win, true)
	end
	if help_buf and vim.api.nvim_buf_is_valid(help_buf) then
		pcall(vim.api.nvim_buf_delete, help_buf, { force = true })
	end
	help_win, help_buf = nil, nil
end

--- Generate help content showing all plugin keybindings
--- @return string[] output The help text lines
--- @return number max_length Maximum length of text
function M.generate_help_content()
	local keybinds = require("vscpanel.keybinds").keybinds()
	local output = {
		"vscpanel.nvim mappings",
		"==================",
		"",
		-- "Global Keybindings:",
		-- "",
		-- "Terminal Window Keybindings:",
		-- "",
		-- string.format("  %-20s  %s", "g?", "Show this help"),
		-- "",
		-- "Terminal Tabs Keybindings:",
		-- "",
		-- string.format("  %-20s  %s", "<Enter>", "Switch to terminal"),
		-- string.format("  %-20s  %s", "<LeftMouse>", "Click to switch/close"),
		-- string.format("  %-20s  %s", "d", "Close terminal"),
		-- string.format("  %-20s  %s", "r", "Rename terminal"),
		-- string.format("  %-20s  %s", "q / <Esc>", "Close terminal tabs"),
		-- string.format("  %-20s  %s", "g?", "Show this help"),
		-- "",
		-- "Press <Esc> or q to close this help",
	}

	for _, keybind in ipairs(keybinds) do
		table.insert(output, string.format("%s %40s", keybind.keymap, keybind.description))
	end

	-- Calculate the max length of the help output.
	local max_length = 0
	for _, line in ipairs(output) do
		max_length = math.max(max_length, vim.fn.strdisplaywidth(line))
	end

	return output, max_length
end

--- Show help in a floating window
function M.show_help()
	close_help() -- Close any existing help window

	local content, max_width = M.generate_help_content()

	-- Create buffer
	help_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, content)
	vim.bo[help_buf].modifiable = false
	vim.bo[help_buf].buftype = "nofile"
	vim.bo[help_buf].bufhidden = "wipe"

	-- Calculate window size and position
	local width = math.min(max_width + 4, vim.o.columns - 10)
	local height = math.min(#content + 2, vim.o.lines - 10)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create floating window
	help_win = vim.api.nvim_open_win(help_buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		border = "rounded",
		style = "minimal",
		focusable = true,
		noautocmd = true,
		title = " PanelTerm Help ",
		title_pos = "center",
	})

	-- Set window options
	vim.api.nvim_set_option_value("cursorline", true, { win = help_win })
	vim.api.nvim_set_option_value("wrap", false, { win = help_win })

	-- Set up keybindings for the help window
	vim.keymap.set("n", "<Esc>", close_help, { buffer = help_buf, silent = true })
	vim.keymap.set("n", "q", close_help, { buffer = help_buf, silent = true })
	vim.keymap.set("n", "g?", close_help, { buffer = help_buf, silent = true })

	-- Auto-close when leaving the window
	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		buffer = help_buf,
		once = true,
		callback = close_help,
	})
end

--- Displays the help text.
--- @return string[] output The output
--- @return number max_length Maximum length of text
function M.display()
	return M.generate_help_content()
end

return M
