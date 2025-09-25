local M = {}

--- @class panel.Command
--- @field name string
--- @field opts table
--- @field command function

--- @type panel.Command[]
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
			require("vscpanel.views.terminal.shell-picker").open()
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
