local lpeg = require("lpeglabel")
local l = {}
lpeg.locale(l)

local string = lpeg.P
local capture = lpeg.C
local group = lpeg.Cg
local to_table = lpeg.Ct
local helper = require("nvim-kitty.parsers.helper")
local h = require("nvim-kitty.parsers.helper")
local path = helper.path
local colon = helper.colon
local char = helper.char
local linefeed = helper.linefeed
local rest_of_line = helper.rest_of_line
local error_type = helper.error_type
local set_tag = helper.set_tag
local text = helper.text
local repeat1 = helper.repeat1
local while_not1 = helper.while_not1
local optional = helper.optional
local flatten = helper.flatten

local warn = h.set_tag("severity", vim.diagnostic.severity.WARN)
local error = h.set_tag("severity", vim.diagnostic.severity.ERROR)

local elixir_dir = vim.fn.system("which elixir"):match("(.*)/bin/elixir")

local mix_error_detail = (
	string("  ")
	* path
	* colon
	* group(capture(l.digit ^ 1) / tonumber, "lnum")
	* colon
	* group(capture(char ^ 0) / vim.trim, "module")
)

local mix_error = to_table(
	group(string("error") / error_type, "severity")
		* colon
		* group(rest_of_line / vim.trim, "text")
		* mix_error_detail
		* linefeed
)

local mix_warning = to_table(
	group(string("warning") / error_type, "severity")
		* colon
		* group(rest_of_line / vim.trim, "text")
		* mix_error_detail
		* linefeed
)

local mix_compile_error =
	to_table(string("** (CompileError) ") * path * colon * group(capture(char ^ 0) / vim.trim, "text"))

local function add_app_path(tbl)
	local mod = tbl["module"]

	if not mod or mod == "" then
		if vim.fn.filereadable(tbl.path) == 1 then
			return tbl
		end
		local p = vim.fn.findfile(tbl.path, "*/*")
		if p then
			tbl.path = p
			return tbl
		else
			return tbl
		end
	end

	if mod == "elixir" then
		-- tbl.path = elixir_dir .. "/lib/elixir/" .. tbl.path
		return tbl
	end

	if vim.fn.isdirectory("apps/" .. mod) == 1 then
		tbl.path = "apps/" .. mod .. "/" .. tbl.path
	end

	if vim.fn.isdirectory("deps/" .. mod) == 1 then
		tbl.path = "deps/" .. mod .. "/" .. tbl.path
	end

	return tbl
end

local function extract_app_name(str)
	return str:match("%((%S+)%s+%S+%)")
end

local app_name = ("(" * while_not1(string(")")) * ")") / extract_app_name

local mix_path = h.ws_
	* h.to_table(
		h.group(optional(app_name), "module")
			* h.ws
			* h.path
			* h.colon
			* h.group(h.capture(l.digit ^ 1) / tonumber, "lnum")
			* h.colon
			* h.group(h.capture(char ^ 1) / vim.trim, "text")
	)
	/ error
	/ add_app_path

local mix_warning_multiline = h.to_table(
	h.ws_
		* string("warning:")
		* group(rest_of_line / vim.trim, "text")
		* h.while_not1("└─")
		* string("└─")
		* h.ws_
		* h.group(optional(app_name), "module")
		* h.ws
		* h.path
		* h.colon
		* h.group(h.capture(l.digit ^ 1) / tonumber, "lnum")
		* h.colon
		* h.group(h.capture(l.digit ^ 1) / vim.trim, "col")
) / warn / add_app_path

local mix_test = to_table(
	(h.ws_ * group(capture(text) / vim.trim, "test_name") * linefeed)
		* (h.ws_ * path * colon * group(capture(repeat1(l.digit)) / tonumber, "lnum") * linefeed)
		* (h.ws_ * group(capture(while_not1(string("\n     code:"))) / vim.trim, "text"))
		* optional( --
			linefeed
				* (h.ws_ * "code:" * rest_of_line)
				* optional( --
					(h.ws_ * "left:" * rest_of_line) --
						* (h.ws_ * "right:" * rest_of_line) --
				)
				* (h.ws_ * "stacktrace:" * rest_of_line) --
				* to_table(optional(mix_path * linefeed))
		)
)
	/ set_tag("severity", vim.diagnostic.ERROR)
	/ function(tbl)
		-- Add the test name to the text
		if not tbl[1] then
			return tbl
		end
		for _index, value in ipairs(tbl[1]) do
			value.text = tbl.test_name .. "\n\t" .. value.text
		end
		return tbl
	end
	/ flatten

return mix_test + mix_path + mix_compile_error + mix_error + mix_warning + mix_warning_multiline
