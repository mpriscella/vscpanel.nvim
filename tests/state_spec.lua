local assert = require("luassert")

describe("vscpanel state", function()
	after_each(require("utils").cleanup)

	it("has the correct default values", function()
		local state = require("vscpanel.state")
		local views = require("vscpanel.views")

		local window_id = state.window_id()
		assert.is_truthy(window_id == nil)

		local terminals = state.terminals()
		assert.is_truthy(type(terminals) == "table" and next(terminals) == nil) -- ERROR

		local is_maximized = state.is_maximized()
		assert.is_truthy(is_maximized == false)

		local active_terminal = state.active_terminal()
		assert.is_truthy(active_terminal == nil)

		local active_view = state.active_view()
		assert.is_truthy(active_view == views.views.TERMINAL)
	end)

	it("successfully sets active view", function()
		local state = require("vscpanel.state")
		local views = require("vscpanel.views")

		state.dispatch("set_active_view", views.views.PROBLEMS)
		assert.is_equal(views.views.PROBLEMS, state.active_view())

		state.dispatch("set_active_view", views.views.TERMINAL)
		assert.is_equal(views.views.TERMINAL, state.active_view())
	end)
end)
