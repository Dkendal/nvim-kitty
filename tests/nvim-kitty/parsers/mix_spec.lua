local here = require("test_support").here
local parser = require("nvim-kitty.parsers").wrap(require("nvim-kitty.parsers.vimgrep"))

describe("mix parser", function()
	pending("works", function()
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

	pending("parses mix test output", function()
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

	it("can match a line from a stacktrace", function()
		local parser = require("nvim-kitty.parsers").parser_for_tool("mix")

		local corpus = here([[
					 (elixir 1.16.3) lib/keyword.ex:599: Keyword.fetch!/2
					 (app 1.0.0) lib/app/module/interface.ex:224: App.Module.Data.to_param/3
					 test/app/module/name_test.exs:26: (test)
		]])

		local r, l, e = parser:match(corpus)

		assert.equal(nil, l)
		assert.equal(nil, e)
		assert.same({
			{
				path = "lib/keyword.ex",
				module = "elixir",
				lnum = 599,
				text = "Keyword.fetch!/2",
			},
			{
				path = "lib/app/module/interface.ex",
				module = "app",
				lnum = 224,
				text = "App.Module.Data.to_param/3",
			},
			{
				path = "test/app/module/name_test.exs",
				lnum = 26,
				test_name = "(test)",
			},
		}, r)
	end)

	pending("matches lines to umbrella apps", function()
		local parser = require("nvim-kitty.parsers").parser_for_tool("mix")

		local corpus = here([[
			1) test text (Module.Name)
				 apps/app/test/app/module/name_test.exs:18
				 ** (KeyError) error
				 code: {:ok, %{}} = error
				 stacktrace:
					 (elixir 1.16.3) lib/keyword.ex:599: Keyword.fetch!/2
					 (app 1.0.0) lib/app/module/interface.ex:224: App.Module.Data.to_param/3
					 test/app/module/name_test.exs:26: (test)
		]])

		local r, l, e = parser:match(corpus)

		assert.equal(nil, l)
		assert.equal(nil, e)
		assert.same({
			{
				path = "apps/app/test/app/module/name_test.exs",
				lnum = 18,
				test_name = "test text (Module.Name)",
				test_number = "1",
				text = "** (KeyError) error",
				code = "{:ok, %{}} = error",
			},
			{
				path = "(elixir 1.16.3) lib/keyword.ex",
				lnum = 599,
				text = "Keyword.fetch!/2",
			},
			{
				path = "(app 1.0.0) lib/app/module/interface.ex",
				lnum = 224,
				text = "App.Module.Data.to_param/3",
			},
			{
				path = "test/app/module/name_test.exs",
				lnum = 26,
				test_name = "(test)",
			},
		}, r)
	end)
end)
