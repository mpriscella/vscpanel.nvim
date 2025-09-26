--[[
  File: winbar.lua
  Description:
    Provides functions for managing the lifestyle of the panel.
]]

local M = {}

--- Get the current configuration from the main module
--- @return table: Configuration options
local function get_opts()
	local vscpanel = require("vscpanel")
	local config = require("vscpanel.config")

	return vscpanel.opts or config.defaults
end

-- Setup winbar functions in a namespace
function M.setup()
	local state = require("vscpanel.state")
	local constants = require("vscpanel.constants")

	vim.api.nvim_set_hl(0, "WinBar", { link = "Normal" })
	vim.api.nvim_set_hl(0, "WinBarNC", { link = "NormalNC" })

	local aug = vim.api.nvim_create_augroup("vscpanel.nvim", { clear = true })
	vim.api.nvim_create_autocmd("User", {
		group = aug,
		pattern = "WinbarUpdate",
		callback = function()
			M.update()
		end,
	})

	_G[constants.NAMESPACE] = {
		add_default_terminal = function()
			local win = state.window_id()
			if type(win) ~= "integer" then
				return
			end

			require("vscpanel.views.terminal").create_terminal(win)
			require("vscpanel").ensure_insert()
		end,
		help = function()
			require("vscpanel").show_help()
		end,
		hide_panel = function()
			require("vscpanel.panel").close_panel()
		end,
		launch_profile = function()
			require("vscpanel.views.terminal.shell-picker").toggle()
		end,
		toggle_panel_size = function()
			require("vscpanel").max_toggle()
		end,
	}
end

--- Build the New Terminal icon.
--- @return string
local function new_terminal_icon()
	local opts = get_opts()
	local icon = opts.icons.terminal.new_terminal
	local constants = require("vscpanel.constants")

	return table.concat({
		"%@v:lua.",
		constants.NAMESPACE,
		".add_default_terminal",
		"@" .. icon .. "%T",
	})
end

--- Build the menu icon.
--- @return string
local function launch_profile_icon()
	local opts = get_opts()
	local icon = opts.icons.terminal.launch_profile
	local constants = require("vscpanel.constants")

	return table.concat({
		"%@v:lua.",
		constants.NAMESPACE,
		".launch_profile",
		"@" .. icon .. "%T",
	})
end

--- Builds the toggle_panel_size icon.
--- @return string
local function toggle_panel_size_icon()
	local opts = get_opts()
	local icon = opts.icons.panel.toggle_panel_size
	local constants = require("vscpanel.constants")

	return table.concat({
		"%@v:lua.",
		constants.NAMESPACE,
		".toggle_panel_size",
		"@" .. icon .. "%T",
	})
end

--- Builds the close icon.
--- @return string
local function hide_panel_icon()
	local opts = get_opts()
	local icon = opts.icons.panel.hide_panel
	local constants = require("vscpanel.constants")

	return table.concat({
		"%@v:lua.",
		constants.NAMESPACE,
		".hide_panel",
		"@" .. icon .. "%T",
	})
end

--- Builds the help icon.
--- @return string
local function help_icon()
	local opts = get_opts()
	local icon = opts.icons.terminal.help
	local constants = require("vscpanel.constants")

	return table.concat({
		"%@v:lua.",
		constants.NAMESPACE,
		".help",
		"@" .. icon .. " %T",
	})
end

-- @param num number
-- @return string circle The rendered circle.
-- local function circle(num)
-- 	local panel_blue = "#43589c"
-- 	vim.api.nvim_set_hl(0, "ActiveView", { underline = true, fg = "white", sp = panel_blue })
--
-- 	vim.api.nvim_set_hl(0, "BlueCircle", { fg = panel_blue })
-- 	vim.api.nvim_set_hl(0, "BlueCircleMiddle", { fg = "white", bg = panel_blue })
--
-- 	return table.concat({
-- 		"%#BlueCircle#",
-- 		"%#BlueCircleMiddle#",
-- 		num,
-- 		"%#BlueCircle#",
-- 		"%#StatusLine#",
-- 	})
-- end

-- @return number count
-- local function get_visible_diagnostic_count()
-- 	local count = 0
-- 	local wins = vim.api.nvim_tabpage_list_wins(0)
-- 	for _, win_id in ipairs(wins) do
-- 		local buf = vim.api.nvim_win_get_buf(win_id)
-- 		local diagnostics = vim.diagnostic.count(buf)
-- 		for _, v in pairs(diagnostics) do
-- 			count = count + v
-- 		end
-- 	end
-- 	return count
-- end

-- local function problems_view_action()
-- 	local views = require("vscpanel.views")
-- 	local active_view = views.active_view()
-- 	local count = get_visible_diagnostic_count()
-- 	local constants = require("vscpanel.constants")
--
-- 	return table.concat({
-- 		active_view == views.views.PROBLEMS and "%#ActiveView#" or "",
-- 		"%@v:lua.",
-- 		constants.NAMESPACE,
-- 		".view_select_problems",
-- 		"@PROBLEMS",
-- 		"%#StatusLine#",
-- 		" ",
-- 		count > 0 and circle(count) or "",
-- 		"%T",
-- 		"%#StatusLine#",
-- 	})
-- end

-- local function terminal_view_action()
-- 	local views = require("vscpanel.views")
-- 	local active_view = views.active_view()
-- 	local constants = require("vscpanel.constants")
--
-- 	return table.concat({
-- 		active_view == views.views.TERMINAL and "%#ActiveView#" or "",
-- 		"%@v:lua.",
-- 		constants.NAMESPACE,
-- 		".view_select_terminal",
-- 		"@TERMINAL%T",
-- 		"%#StatusLine#",
-- 	})
-- end

--- Update the winbar.
function M.update()
	local state = require("vscpanel.state")
	local win = state.window_id()

	-- Early return if no valid window
	if not win or not vim.api.nvim_win_is_valid(win) then
		return
	end

	local winbar_content = table.concat({
		-- Left. This is where the view selection interface will be.
		-- problems_view_action(),
		-- "    ",
		-- terminal_view_action(),
		"%=",
		-- Center. Nothing.
		"%=",
		-- Right. Panel management.
		help_icon(),
		"  ",
		new_terminal_icon(),
		" ",
		launch_profile_icon(),
		"%#Conceal#  |  %*",
		toggle_panel_size_icon(),
		"  ",
		hide_panel_icon(),
		"   ",
	})

	local ok = pcall(vim.api.nvim_set_option_value, "winbar", winbar_content, { win = win })
	if not ok then
		vim.notify("Error updating winbar.", vim.log.levels.ERROR)
	end
end

return M
