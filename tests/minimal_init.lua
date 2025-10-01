-- Minimal init for running in headless tests and dev.

-- Add repo root to runtimepath so plugin/ and lua/ are discovered
local cwd = vim.fn.getcwd()
vim.opt.rtp:append(cwd)

-- Ensure lua module path includes this repo's lua/ and tests/
package.path = package.path .. ";" .. cwd .. "/lua/?.lua;" .. cwd .. "/lua/?/init.lua;" .. cwd .. "/tests/?.lua"

-- Ensure plenary is available: try require, else clone locally under .deps
local function ensure_plenary()
	if pcall(require, "plenary") then
		return
	end

	local deps = cwd .. "/.deps"
	local plenary_path = deps .. "/plenary.nvim"
	if vim.fn.isdirectory(plenary_path) == 0 then
		if vim.fn.isdirectory(deps) == 0 then
			vim.fn.mkdir(deps, "p")
		end

		local url = "https://github.com/nvim-lua/plenary.nvim"
		vim.notify("vscpanel.nvim: Cloning plenary.nvim into " .. plenary_path, vim.log.levels.INFO)
		vim.fn.system({ "git", "clone", "--depth=1", url, plenary_path })
		if vim.v.shell_error ~= 0 then
			error("Failed to clone plenary.nvim. Ensure git is installed and network is available.")
		end
	end

	-- Add to runtimepath and lua path
	vim.opt.rtp:append(plenary_path)
	package.path = package.path .. ";" .. plenary_path .. "/lua/?.lua;" .. plenary_path .. "/lua/?/init.lua"
	if not pcall(require, "plenary") then
		error("Failed to load plenary.nvim from " .. plenary_path)
	end
end

ensure_plenary()

-- Optional: quiet UI noise in headless runs
vim.o.swapfile = false
vim.o.writebackup = false
vim.o.backup = false
vim.o.more = false
vim.o.hidden = true

-- Plugin auto-setup is handled by plugin/vscpanel.lua via loaded guard
