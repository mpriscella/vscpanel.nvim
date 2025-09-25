local M = {
	views = {
		PROBLEMS = 1,
		TERMINAL = 2,
	},
}

--- Gets the active view.
--- @return number active_view
function M.active_view()
	return require("vscpanel.state").active_view()
end

return M
