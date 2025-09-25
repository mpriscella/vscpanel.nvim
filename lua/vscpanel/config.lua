--- @class panel.Config
--- @field icons panel.Config.Icons? Icon definitions for the plugin.
--- @field shell string? The path to an executable shell.
--- @field size integer? The size of the panel when the position is "bottom" or "top".
--- @field position string? The position of the panel. Either "bottom" (default), "top", "left", or "right".

--- @class panel.Config.Icons
--- @field close_terminal string?
--- @field hide_panel string?
--- @field launch_profile string?
--- @field toggle_panel_size string?
--- @field new_terminal string?

local M = {
	--- @type panel.Config
	defaults = {
		size = 18,
		shell = vim.o.shell,
		position = "bottom",
		icons = {
			close_terminal = "",
			-- close_terminal = "", -- INFO: Disabling close terminal icon for now.
			help = "󰋖",
			hide_panel = "",
			launch_profile = "",
			toggle_panel_size = " ",
			new_terminal = "",
		},
	},
}

--- Normalize and validate the passed in opts.
--- @param opts table|nil User configuration options
--- @return panel.Config config
function M.normalize(opts)
	opts = vim.tbl_deep_extend("force", M.defaults, opts or {})

	-- Validate size.
	if type(opts.size) ~= "number" or opts.size <= 0 then
		vim.notify(
			"vscpanel: 'size' must be a positive number, using default: " .. M.defaults.size,
			vim.log.levels.WARN
		)
		opts.size = M.defaults.size
	end

	-- Validate shell.
	if type(opts.shell) ~= "string" or opts.shell == "" or not vim.fn.executable(opts.shell) then
		vim.notify("vscpanel: 'shell' must be a non-empty string, using default", vim.log.levels.WARN)
		opts.shell = M.defaults.shell
	end

	-- Validate position.
	local valid_positions = { "bottom", "top", "left", "right" }
	if not vim.tbl_contains(valid_positions, opts.position) then
		vim.notify("vscpanel: 'position' must be one of: " .. table.concat(valid_positions, ", "), vim.log.levels.WARN)
		opts.position = M.defaults.position
	end

	return opts
end

return M
