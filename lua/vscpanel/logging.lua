local M = {}

local log_level = vim.log.levels.WARN

--- @param level string
function M.set_level(level)
	log_level = level
end

--- @param msg string
function M.debug(msg)
	if log_level <= vim.log.levels.DEBUG then
		vim.notify("[vscpanel.nvim] " .. msg, vim.log.levels.DEBUG)
	end
end

--- @param msg string
function M.error(msg)
	if log_level <= vim.log.levels.ERROR then
		vim.notify("[vscpanel.nvim] " .. msg, vim.log.levels.ERROR)
	end
end

--- @param msg string
function M.info(msg)
	if log_level <= vim.log.levels.INFO then
		vim.notify("[vscpanel.nvim] " .. msg, vim.log.levels.INFO)
	end
end

--- @param msg string
function M.trace(msg)
	if log_level <= vim.log.levels.TRACE then
		vim.notify("[vscpanel.nvim] " .. msg, vim.log.levels.TRACE)
	end
end

--- @param msg string
function M.warn(msg)
	if log_level <= vim.log.levels.WARN then
		vim.notify("[vscpanel.nvim] " .. msg, vim.log.levels.WARN)
	end
end

return M
