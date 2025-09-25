local assert = require("luassert")

describe("vscpanel position", function()
	after_each(require("utils").cleanup)

	it("creates panel at bottom position (default)", function()
		require("vscpanel").setup({
			position = "bottom",
			size = 10,
		})

		-- Get initial window before creating panel
		local initial_win = vim.api.nvim_get_current_win()

		require("vscpanel.panel").toggle_panel()
		vim.wait(100)

		local panel_win = vim.api.nvim_get_current_win()
		local height = vim.api.nvim_win_get_height(panel_win)

		-- Should be the configured size
		assert.are.equal(10, height)

		-- Verify position: bottom panel should be below the initial window
		local initial_pos = vim.api.nvim_win_get_position(initial_win)
		local panel_pos = vim.api.nvim_win_get_position(panel_win)
		assert.is_true(panel_pos[1] > initial_pos[1]) -- panel row > initial row (below)
	end)

	it("creates panel at top position", function()
		require("vscpanel").setup({
			position = "top",
			size = 15,
		})

		-- Create a dummy window to compare position against
		vim.cmd("new")
		local reference_win = vim.api.nvim_get_current_win()

		require("vscpanel.panel").toggle_panel()
		vim.wait(100)

		local panel_win = vim.api.nvim_get_current_win()
		local height = vim.api.nvim_win_get_height(panel_win)

		-- Should be the configured size
		assert.are.equal(15, height)

		-- Verify position: top panel should be above the reference window
		local reference_pos = vim.api.nvim_win_get_position(reference_win)
		local panel_pos = vim.api.nvim_win_get_position(panel_win)
		assert.is_true(panel_pos[1] < reference_pos[1]) -- panel row < reference row (above)
	end)

	it("creates panel at left position", function()
		require("vscpanel").setup({
			position = "left",
			size = 40, -- Size is ignored for vertical splits
		})

		-- Get initial window before creating panel
		local initial_win = vim.api.nvim_get_current_win()

		require("vscpanel.panel").toggle_panel()
		vim.wait(100)

		local panel_win = vim.api.nvim_get_current_win()
		local width = vim.api.nvim_win_get_width(panel_win)

		-- Verify we got a reasonable width (not configured size)
		assert.is_true(width > 0)
		assert.is_true(width < 200) -- Reasonable upper bound for headless testing

		-- Verify position: left panel should be to the left of the initial window
		local initial_pos = vim.api.nvim_win_get_position(initial_win)
		local panel_pos = vim.api.nvim_win_get_position(panel_win)
		assert.is_true(panel_pos[2] < initial_pos[2]) -- panel col < initial col (left)
	end)

	it("creates panel at right position", function()
		require("vscpanel").setup({
			position = "right",
			size = 50, -- Size is ignored for vertical splits
		})

		-- Get initial window before creating panel
		local initial_win = vim.api.nvim_get_current_win()

		require("vscpanel.panel").toggle_panel()
		vim.wait(100)

		local panel_win = vim.api.nvim_get_current_win()
		local width = vim.api.nvim_win_get_width(panel_win)

		-- Verify we got a reasonable width (not configured size)
		assert.is_true(width > 0)
		assert.is_true(width < 200) -- Reasonable upper bound for headless testing

		-- Verify position: right panel should be to the right of the initial window
		local initial_pos = vim.api.nvim_win_get_position(initial_win)
		local panel_pos = vim.api.nvim_win_get_position(panel_win)
		assert.is_true(panel_pos[2] > initial_pos[2]) -- panel col > initial col (right)
	end)

	it("falls back to bottom for invalid position", function()
		require("vscpanel").setup({
			position = "invalid",
			size = 12,
		})

		-- Get initial window before creating panel
		local initial_win = vim.api.nvim_get_current_win()

		require("vscpanel.panel").toggle_panel()
		vim.wait(100)

		local panel_win = vim.api.nvim_get_current_win()
		local height = vim.api.nvim_win_get_height(panel_win)

		-- Should be the configured size, using bottom fallback
		assert.are.equal(12, height)

		-- Verify it behaves like bottom position (below initial window)
		local initial_pos = vim.api.nvim_win_get_position(initial_win)
		local panel_pos = vim.api.nvim_win_get_position(panel_win)
		assert.is_true(panel_pos[1] > initial_pos[1]) -- panel row > initial row (below)
	end)
end)
