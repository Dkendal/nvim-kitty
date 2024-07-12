local here = require("test_support").here
local parser = require("nvim-kitty.parsers").wrap(require("nvim-kitty.parsers.vimgrep"))

describe("vimgrep parser", function()
	it("works", function()
		local corpus = here([[
			nvim-kitty on  lpeg via 🌙 v5.1 took 6s
			❯ rg --vimgrep kitty
			lua/nvim-kitty.lua:3:25:local a = require("nvim-kitty.async")
			lua/nvim-kitty.lua:44:29:	local out = vim.fn.system("kitty @ ls")
		]])

		local r, l, e = parser:match(corpus)

		assert.are.equal(nil, l)
		assert.are.equal(nil, e)
		assert.are.same({
			{
				col = 25,
				lnum = 3,
				path = "lua/nvim-kitty.lua",
				text = 'local a = require("nvim-kitty.async")',
			},
			{
				col = 29,
				lnum = 44,
				path = "lua/nvim-kitty.lua",
				text = 'local out = vim.fn.system("kitty @ ls")',
			},
		}, r)
	end)
end)
