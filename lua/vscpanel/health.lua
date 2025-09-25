local M = {}

--- Check health.
function M.check()
	vim.health.start("vscpanel.nvim")

	-- Check if plugin is loaded.
	local ok, vscpanel = pcall(require, "vscpanel")
	if not ok then
		vim.health.error("Failed to load vscpanel module")
		return
	end

	vim.health.ok("vscpanel module loaded successfully")

	-- Check configuration.
	local opts = vscpanel.opts
	if not opts then
		vim.health.error("No configuration found")
		return
	end

	-- Check size configuration.
	if type(opts.size) == "number" and opts.size > 0 then
		vim.health.ok("size is properly configured: " .. opts.size)
	else
		vim.health.error("size must be a positive number, got: " .. tostring(opts.size))
	end

	-- Check shell configuration.
	if type(opts.shell) == "string" and opts.shell ~= "" and vim.fn.executable(opts.shell) then
		vim.health.ok("shell is configured: " .. opts.shell)
	else
		vim.health.warn("shell configuration invalid: " .. tostring(opts.shell))
	end

	-- Check position.
	local valid_positions = { "bottom", "top", "left", "right" }
	if vim.tbl_contains(valid_positions, opts.position) then
		vim.health.ok("position is valid: " .. opts.position)
	else
		vim.health.warn("position should be one of: " .. table.concat(valid_positions, ", "))
	end

	-- Check Neovim version.
	if vim.fn.has("nvim-0.8") == 1 then
		vim.health.ok("Neovim version is compatible")
	else
		vim.health.error("Neovim 0.8+ required")
	end
end

return M
