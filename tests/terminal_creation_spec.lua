local assert = require("luassert")

describe("vscpanel terminal creation functionality", function()
	local panel, state, terminal

	before_each(function()
		require("tests.utils").cleanup()
		panel = require("vscpanel.panel")
		state = require("vscpanel.state")
		terminal = require("vscpanel.views.terminal")
	end)

	describe("new terminal", function()
		it("is created", function()
			panel.toggle_panel()
			local terminals = state.terminals()

			assert.are.equal(#terminals, 1)
			local window_id = state.window_id()
			terminal.create_terminal(window_id, "/bin/bash")
			terminals = state.terminals()

			assert.are.equal(#terminals, 2)
		end)
	end)
end)
