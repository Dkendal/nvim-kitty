local here = require("test_support").here
local M = require("nvim-kitty")

describe("vimgrep parser", function()
	it("works", function()
		local parser = require("nvim-kitty.parsers").parser_for_tool("vimgrep")

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

describe("mix parser", function()
	it("works", function()
		local parser = require("nvim-kitty.parsers").parser_for_tool("mix")

		local corpus = here([[
			Compiling 1 file (.ex)
			error: undefined variable "url"
				lib/theme_scanner/http.ex:12: ThemeScanner.Http.download_theme_assets/2

			warning: variable "tag" is unused (if the variable is not meant to be used, prefix it with an underscore)
				lib/theme_scanner/http.ex:99: ThemeScanner.Http.do_collect_subresources/2


			== Compilation error in file lib/theme_scanner/http.ex ==
			** (CompileError) lib/theme_scanner/http.ex: cannot compile module ThemeScanner.Http (errors have been logged)
		]])

		local r, l, e = parser:match(corpus)

		assert.equal(nil, l)
		assert.equal(nil, e)
		assert.same({
			{
				path = "lib/theme_scanner/http.ex",
				lnum = 12,
				text = 'undefined variable "url"',
				module = "ThemeScanner.Http.download_theme_assets/2",
				type = vim.diagnostic.severity.ERROR,
			},
			{
				path = "lib/theme_scanner/http.ex",
				lnum = 99,
				text = 'variable "tag" is unused (if the variable is not meant to be used, prefix it with an underscore)',
				module = "ThemeScanner.Http.do_collect_subresources/2",
				type = vim.diagnostic.severity.WARN,
			},
			{
				path = "lib/theme_scanner/http.ex",
				text = "cannot compile module ThemeScanner.Http (errors have been logged)",
			},
		}, r)
	end)

	it("parses mix test output", function()
		local parser = require("nvim-kitty.parsers").parser_for_tool("mix")

		local corpus = here([[

			....
			12:43:26.167 [info] GET hello world


				1) test js word based bag of words (ThemeScannerTest)
					 test/theme_scanner_test.exs:36
					 ** (MatchError) no match of right hand side value: []
					 code: for n_gram <- 2..12 do
					 stacktrace:
						 test/theme_scanner_test.exs:42: a
						 (elixir 1.15.5) lib/enum.ex:4356: b
						 test/theme_scanner_test.exs:41: (test)
		]])

		local r, l, e = parser:match(corpus)

		assert.equal(nil, l)
		assert.equal(nil, e)
		assert.same({
			{
				lnum = 36,
				path = "test/theme_scanner_test.exs",
				test_name = "test js word based bag of words (ThemeScannerTest)",
				test_number = "1",
				text = "** (MatchError) no match of right hand side value: []",
				code = "for n_gram <- 2..12 do",
			},
			{
				lnum = 42,
				path = "test/theme_scanner_test.exs",
				text = "a",
			},
			{
				lnum = 4356,
				path = "(elixir 1.15.5) lib/enum.ex",
				text = "b",
			},
			{
				lnum = 41,
				path = "test/theme_scanner_test.exs",
				text = "(test)",
			},
		}, r)
	end)
end)
