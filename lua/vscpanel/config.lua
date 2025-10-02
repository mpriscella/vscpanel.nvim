--- @class vscpanel.Config
--- @field icons vscpanel.Config.Icons?
--- @field shell string? The path to an executable shell.
--- @field size integer? The size of the panel when the position is "bottom" or "top".
--- @field position string? The position of the panel. Either "bottom" (default), "top", "left", or "right".

--- @class vscpanel.Config.Icons
--- @field panel vscpanel.Config.Icons.Panel?
--- @field terminal vscpanel.Config.Icons.Terminal?

--- @class vscpanel.Config.Icons.Panel
--- @field hide_panel string?
--- @field toggle_panel_size string?

--- @class vscpanel.Config.Icons.Terminal
--- @field close_terminal string?
--- @field help string?
--- @field launch_profile string?
--- @field new_terminal string?

--- @type vscpanel.Config
local defaults = {
	size = 18,
	shell = vim.o.shell,
	position = "bottom",
	icons = {
		panel = {
			hide_panel = "",
			toggle_panel_size = " ",
		},
		terminal = {
			close_terminal = "",
			-- close_terminal = "", -- INFO: Disabling close terminal icon for now.
			help = "󰋖",
			launch_profile = "",
			new_terminal = "",
		},
	},
}

local M = {
	defaults = defaults,
}

--- Normalize and validate the passed in opts.
--- @param opts table|nil User configuration options
--- @return vscpanel.Config config
function M.normalize(opts)
	opts = vim.tbl_deep_extend("force", M.defaults, opts or {})

	-- Validate size.
	if type(opts.size) ~= "number" or opts.size <= 0 then
		require("vscpanel.logging").warn(
			"vscpanel.nvim: 'size' must be a positive number, using default: " .. M.defaults.size
		)
		opts.size = M.defaults.size
	end

	-- Validate shell.
	if type(opts.shell) ~= "string" or opts.shell == "" or not vim.fn.executable(opts.shell) then
		require("vscpanel.logging").warn("vscpanel.nvim: 'shell' must be a non-empty string, using default")
		opts.shell = M.defaults.shell
	end

	-- Validate position.
	local valid_positions = { "bottom", "top", "left", "right" }
	if not vim.tbl_contains(valid_positions, opts.position) then
		require("vscpanel.logging").warn(
			"vscpanel.nvim: 'position' must be one of: " .. table.concat(valid_positions, ", ")
		)
		opts.position = M.defaults.position
	end

	return opts
end

return M
