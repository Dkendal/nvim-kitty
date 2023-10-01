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

describe("something", function()
	it("does the thing", function()
		local lpeg = require("lpeglabel")
		local l = {}
		lpeg.locale(l)
		local string, set, range, capture, tag, to_table = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Cg, lpeg.Ct
		local lf = string("\n") + string("\r\n")
		local spc = set(" \t") ^ 0
		local tab = string("\t")

		local function ignore(p)
			return capture(p) / ""
		end

		local function error_type(string)
			string = string:lower()

			if string == "error" then
				return "e"
			elseif string == "warning" then
				return "w"
			elseif string == "info" then
				return "i"
			elseif string == "note" then
				return "n"
			end
		end

		local any = (1 - lf)
		local colon = string(":")

		-- Explain:
		-- 1 - lf: match any character except lf
		-- ^0: match zero or more times
		-- lf: match line feed
		local line = any ^ 0 * lf

		local mix_error_detail = (
			tab
			* tag(capture((any - string(":")) ^ 0), "file_name")
			* colon
			* tag(capture(l.digit ^ 1) / tonumber, "lnum")
			* colon
			* tag(capture(any ^ 0) / vim.trim, "module")
		)

		local file_name = capture(any ^ 1, "file_name")

		local mix_error = to_table(
			tag(string("error") / error_type, "type")
				* colon
				* tag(capture(any ^ 1) / vim.trim, "message")
				* lf
				* mix_error_detail
				* lf
		)

		local mix_warning = to_table(
			tag(string("warning") / error_type, "type")
				* colon
				* tag(capture(any ^ 1) / vim.trim, "message")
				* lf
				* mix_error_detail
				* lf
		)

		local mix_compile_error = to_table(
			string("** (CompileError) ")
				* tag(capture((any - string(":")) ^ 0), "file_name")
				* colon
				* tag(capture(any ^ 0) / vim.trim, "message")
		)

		-- local grammar = string("error:") - 1
		-- match any line
		local grammar = to_table((mix_compile_error + mix_error + mix_warning + line) ^ 0)

		corpus = here([[
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

		local r, lab, errpos = grammar:match(corpus)

		print(vim.inspect({ r = r, lab = lab, errpos = errpos }))

		assert.equal(nil, lab)
		assert.equal(nil, errpos)
		assert.equal("", r)
	end)
end)
