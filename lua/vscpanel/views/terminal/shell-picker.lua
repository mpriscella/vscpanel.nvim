local M = {}

--- @class ShellPicker
--- @field win integer|nil: Window ID (nil when not created)
--- @field buf integer|nil: Buffer ID (nil when not created)
--- @field items string[]: List of valid shells.

--- @type ShellPicker
local menu = {
	win = nil,
	buf = nil,
	items = {},
}

--- Get a list of valid shells in the host system.
--- @return string[] list A sorted list of valid shell labels.
local function valid_shells()
	local shells = {}

	if vim.fn.filereadable("/etc/shells") == 1 then
		for _, line in ipairs(vim.fn.readfile("/etc/shells")) do
			if line:match("^/") and vim.fn.executable(line) == 1 then
				shells[line] = true
			end
		end
	end

	local list = {}
	local default = ""
	for sh in pairs(shells) do
		if sh == vim.o.shell then
			default = vim.fs.basename(sh)
		else
			table.insert(list, vim.fs.basename(sh))
		end
	end
	table.sort(list)
	table.insert(list, 1, default .. " (Default)")
	return list
end

--- Closes the context menu.
local function close_menu()
	if menu.win and vim.api.nvim_win_is_valid(menu.win) then
		pcall(vim.api.nvim_win_close, menu.win, true)
	end
	if menu.buf and vim.api.nvim_buf_is_valid(menu.buf) then
		pcall(vim.api.nvim_buf_delete, menu.buf, { force = true })
	end
	menu.win, menu.buf, menu.items = nil, nil, {}
end

--- Opens the shell picker.
local function open()
	local panel_win = require("vscpanel.state").window_id()

	-- Get window position and size
	local win_pos = vim.api.nvim_win_get_position(panel_win)
	local win_width = vim.api.nvim_win_get_width(panel_win)

	-- Calculate position under the launch_profile icon
	-- The launch_profile icon is in the right side of the winbar
	-- Position it roughly where the launch_profile icon would be
	local row = win_pos[1] + 1 -- Just below the winbar
	local col = win_pos[2] + win_width - 15 -- Near the right side where the icon is

	close_menu()

	menu.items = valid_shells()

	menu.buf = vim.api.nvim_create_buf(false, true)

	local lines = {}
	for i, it in ipairs(menu.items) do
		lines[i] = it
	end

	vim.api.nvim_buf_set_lines(menu.buf, 0, -1, false, lines)

	-- Make it look/behave like a menu
	vim.bo[menu.buf].modifiable = false
	vim.bo[menu.buf].bufhidden = "wipe"
	vim.bo[menu.buf].filetype = "PanelTermMenu"
	vim.bo[menu.buf].buftype = "nofile"

	-- Size to content
	local width = math.max(
		20,
		vim.fn.max(vim.tbl_map(function(s)
			return #s
		end, lines))
	)
	local height = math.min(#lines, 12)

	-- Keep on screen
	local maxrow = vim.o.lines - 2
	local maxcol = vim.o.columns - 2
	row = math.max(1, math.min(row, maxrow - height))
	col = math.max(1, math.min(col, maxcol - width))

	menu.win = vim.api.nvim_open_win(menu.buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		border = "rounded",
		style = "minimal",
		focusable = true,
		noautocmd = true,
		title = "New Terminal",
		title_pos = "center",
	})

	vim.api.nvim_set_option_value("cursorline", true, { win = menu.win })

	-- Auto-close when leaving/clicking elsewhere
	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		buffer = menu.buf,
		once = true,
		callback = close_menu,
	})

	-- Helpers
	local function item_at_mouse()
		local mp = vim.fn.getmousepos()
		if mp.winid ~= menu.win then
			return nil
		end
		return menu.items[mp.winrow - 1]
	end

	vim.keymap.set("n", "<LeftMouse>", function()
		local item = item_at_mouse()
		if not item then
			return
		end

		close_menu()
		local win = require("vscpanel.state").window_id()
		require("vscpanel.views.terminal").create_terminal(win, item)
		require("vscpanel").ensure_insert()
	end, { buffer = menu.buf, silent = true, nowait = true })

	vim.keymap.set("n", "<CR>", function()
		local l = vim.api.nvim_win_get_cursor(menu.win)[1]
		local it = menu.items[l]
		if not it then
			return
		end

		close_menu()
		local win = require("vscpanel.state").window_id()
		require("vscpanel.views.terminal").create_terminal(win, it)
		require("vscpanel").ensure_insert()
	end, { buffer = menu.buf, silent = true })

	vim.keymap.set("n", "<Esc>", close_menu, { buffer = menu.buf, silent = true })
end

--- Toggle menu.
function M.toggle()
	open()
end

return M
