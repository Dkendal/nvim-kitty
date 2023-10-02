local M = require("nvim-kitty")

--- Act like a here document with indentation. The indentation of the first line
--- is the baseline, and all other lines are indented to match. Output string
--- should be trimmed of this baseline indentation.
local function here(doc)
	local baseline = string.match(doc, "[^\n]%s*%S")
	baseline = string.gsub(baseline, "%S", "")
	--
	return doc:gsub("^" .. baseline, ""):gsub("\n" .. baseline, "\n"):gsub("%s+\n", "\n"):gsub("%s+$", "\n")
end

describe("here/1", function()
	it("works", function()
		assert.equal(
			"foo\nbar\n",
			here([[
				foo
				bar
			]])
		)
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

			Restarting...
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
				type = "e",
			},
			{
				path = "lib/theme_scanner/http.ex",
				lnum = 99,
				text = 'variable "tag" is unused (if the variable is not meant to be used, prefix it with an underscore)',
				module = "ThemeScanner.Http.do_collect_subresources/2",
				type = "w",
			},
			{
				path = "lib/theme_scanner/http.ex",
				text = "cannot compile module ThemeScanner.Http (errors have been logged)",
			},
			{
				path = "lib/theme_scanner/http.ex",
				lnum = 12,
				text = 'undefined variable "url"',
				module = "ThemeScanner.Http.download_theme_assets/2",
				type = "e",
			},
			{
				path = "lib/theme_scanner/http.ex",
				lnum = 99,
				text = 'variable "tag" is unused (if the variable is not meant to be used, prefix it with an underscore)',
				module = "ThemeScanner.Http.do_collect_subresources/2",
				type = "w",
			},
			{
				path = "lib/theme_scanner/http.ex",
				text = "cannot compile module ThemeScanner.Http (errors have been logged)",
			},
		}, r)
	end)
end)
