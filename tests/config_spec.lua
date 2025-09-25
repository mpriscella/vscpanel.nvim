local assert = require("luassert")
local stub = require("luassert.stub")
local notify_stub

describe("vscpanel.nvim config", function()
	before_each(function()
		require("utils").cleanup()
		notify_stub = stub(vim, "notify")
	end)

	after_each(function()
		notify_stub:revert()
	end)

	it("normalizes the size", function()
		local config = require("vscpanel.config")
		local opts = config.normalize({ size = -10 })
		assert.are.equal(opts.size, config.defaults.size)
		assert
			.stub(notify_stub)
			.was_called_with(
				"vscpanel: 'size' must be a positive number, using default: " .. config.defaults.size,
				vim.log.levels.WARN
			)

		opts = config.normalize({ size = "two" })
		assert.are.equal(opts.size, config.defaults.size)

		opts = config.normalize({ size = 25 })
		assert.are.equal(opts.size, 25)
	end)

	--- TODO: Validate the shell. The difficult part of this is, in CI, validating
	--- that the test shell exists on the runner. It will likely just have to be
	--- hardcoded based on the documented included software for GHA runners.

	it("normalizes the position", function()
		local config = require("vscpanel.config")
		local opts = config.normalize({ position = "bottom" })
		assert.are.equal(opts.position, "bottom")

		opts = config.normalize({ position = "top" })
		assert.are.equal(opts.position, "top")

		opts = config.normalize({ position = "left" })
		assert.are.equal(opts.position, "left")

		opts = config.normalize({ position = "right" })
		assert.are.equal(opts.position, "right")

		opts = config.normalize({ position = "backwards" })
		assert.are.equal(opts.position, config.defaults.position)
		assert
			.stub(notify_stub)
			.was_called_with("vscpanel: 'position' must be one of: bottom, top, left, right", vim.log.levels.WARN)
	end)
end)
