local M = {}

--- @class vscpanel.Command
--- @field name string
--- @field opts table
--- @field command function

--- @type vscpanel.Command[]
local commands = {
	{
		name = "TogglePanel",
		opts = {
			desc = "Toggle Panel",
		},
		command = function()
			require("vscpanel.panel").toggle_panel()
		end,
	},
	{
		--- TODO: This command should only be available if the panel is visible.
		name = "TogglePanelSize",
		opts = {
			desc = "Toggle Panel Size",
		},
		command = function()
			require("vscpanel").max_toggle()
		end,
	},
	{
		name = "ShowTerminalMenu",
		opts = {
			desc = "Show Terminal Menu",
		},
		command = function()
			require("vscpanel.views.terminal.context_menu").open()
		end,
	},
	{
		name = "PanelTermHelp",
		opts = {
			desc = "Show Panel Terminal Help",
		},
		command = function()
			require("vscpanel.help").show_help()
		end,
	},
}

--- Register commands.
function M.register()
	for _, command in ipairs(commands) do
		vim.api.nvim_create_user_command(command.name, command.command, command.opts)
	end
end

return M
