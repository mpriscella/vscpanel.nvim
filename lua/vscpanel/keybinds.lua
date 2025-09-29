local M = {}

--- @class vscpanel.Keybind
--- @field modes table
--- @field keymap string
--- @field callback function
--- @field description string

--- @type vscpanel.Keybind[]
local keybinds = {
	{
		modes = { "n", "t" },
		keymap = "<C-H>",
		callback = function()
			require("vscpanel.help").show_help()
		end,
		description = "panel: Help",
	},
	{
		modes = { "n", "t" },
		keymap = "<C-N>",
		callback = function()
			require("vscpanel.views.terminal.context_menu").toggle()
		end,
		description = "panel: Open Shell Picker",
	},
	{
		modes = { "n", "t" },
		keymap = "<C-space>",
		callback = function()
			require("vscpanel").max_toggle()
		end,
		description = "panel: Maximize / Restore Panel Size",
	},
}

--- Setup buffer-local keybinds for panel terminals.
--- @param buf integer: Buffer ID to set up keybinds for.
function M.setup_terminal_keybinds(buf)
	for _, keybind in ipairs(keybinds) do
		vim.keymap.set(keybind.modes, keybind.keymap, keybind.callback, {
			buffer = buf,
			desc = keybind.description,
		})
	end

	-- Set up autocommand to automatically enter insert mode when entering this terminal buffer.
	local augroup_name = "vscpanel_auto_insert_" .. buf
	vim.api.nvim_create_augroup(augroup_name, { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
		group = augroup_name,
		buffer = buf,
		callback = function()
			local current_buf = vim.api.nvim_get_current_buf()
			if current_buf == buf and vim.bo[buf].buftype == "terminal" then
				require("vscpanel").ensure_insert()
			end
		end,
		desc = "Auto-enter insert mode in panel terminal",
	})
end

--- Returns the defined keybinds.
--- @return vscpanel.Keybind[]
function M.keybinds()
	return keybinds
end

return M
