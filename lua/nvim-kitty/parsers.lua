local lpeg = require("lpeglabel")
local l = {}
lpeg.locale(l)
local string, set, range, capture, tag, to_table = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Cg, lpeg.Ct
local linefeed = string("\n") + string("\r\n")
local spc = set(" \t") ^ 0
local tab = string("\t")

local function ignore(p)
	return capture(p) / ""
end

local function optional(p)
	return p ^ -1
end

local function repeat1(p)
	return p ^ 1
end

local function repeat0(p)
	return p ^ 0
end

local function take_while_not_followed_by1(p)
	return (1 - p) ^ 1
end

--- @param str string
--- @return string
local function error_type(str)
	str = str:lower()

	if str == "error" then
		return vim.diagnostic.severity.ERROR
	elseif str == "warning" then
		return vim.diagnostic.severity.WARN
	elseif str == "info" then
		return vim.diagnostic.severity.INFO
	elseif str == "note" then
		return vim.diagnostic.severity.HINT
	end
end

local char = (1 - linefeed)
local colon = string(":")
local path = tag(capture((char - string(":")) ^ 0) / vim.trim, "path")

-- Explain:
-- 1 - lf: match any character except lf
-- ^0: match zero or more times
-- lf: match line feed
local rest_of_line = char ^ 0 * linefeed
local text = char ^ 1

local mix = nil

local function flatten(tbl, key)
	local sub = {}

	if tbl.path then
		table.insert(sub, tbl)
	end

	for index, value in ipairs(tbl) do
		tbl[index] = nil

		if type(value) == "table" then
			vim.list_extend(sub, { flatten(value) })
		else
			table.insert(sub, value)
		end
	end

	return unpack(sub)
end

local function debug(tbl)
	vim.print(vim.inspect(tbl))
	return tbl
end

local function set_tag(key, value)
	return function(tbl)
		tbl[key] = value
		return tbl
	end
end

do
	local mix_error_detail = (
		string("  ")
		* path
		* colon
		* tag(capture(l.digit ^ 1) / tonumber, "lnum")
		* colon
		* tag(capture(char ^ 0) / vim.trim, "module")
	)

	local mix_error = to_table(
		tag(string("error") / error_type, "severity")
		* colon
		* tag(rest_of_line / vim.trim, "text")
		* mix_error_detail
		* linefeed
	)

	local mix_warning = to_table(
		tag(string("warning") / error_type, "severity")
		* colon
		* tag(rest_of_line / vim.trim, "text")
		* mix_error_detail
		* linefeed
	)

	local mix_compile_error =
			to_table(string("** (CompileError) ") * path * colon * tag(capture(char ^ 0) / vim.trim, "text"))

	local mix_test_stacktrace = to_table(
		string("       ")
		* tag((("(" * (char - ")") ^ 1 * ")") ^ 0), "module")
		* path
		* colon
		* tag(capture(l.digit ^ 1) / tonumber, "lnum")
		* colon
		* tag(capture(char ^ 1) / vim.trim, "text")
	) / set_tag("severity", vim.diagnostic.severity.ERROR)

	local indent2 = string("     ")

	local mix_test = to_table(
				("  " * tag(capture(text) / vim.trim, "test_name") * linefeed)
				* (indent2 * path * colon * tag(capture(repeat1(l.digit)) / tonumber, "lnum") * linefeed)
				* (indent2 * tag(capture(take_while_not_followed_by1(string("\n     code:"))) / vim.trim, "text"))
				* optional(                             --
					linefeed
					* (indent2 * "code:" * rest_of_line)  --
					* optional(                           --
						(indent2 * "left:" * rest_of_line)  --
						* (indent2 * "right:" * rest_of_line) --
					)
					* (indent2 * "stacktrace:" * rest_of_line) --
					* to_table(optional(mix_test_stacktrace * linefeed))
				)
			)
			/ set_tag("severity", vim.diagnostic.ERROR)
			/ function(tbl)
				-- Add the test name to the text
				if not tbl[1] then
					return tbl
				end
				for index, value in ipairs(tbl[1]) do
					value.text = tbl.test_name .. "\n\t" .. value.text
				end
				return tbl
			end
			/ flatten

	mix = mix_test + mix_test_stacktrace + mix_compile_error + mix_error + mix_warning
end

local vimgrep = to_table(
	path
	* colon
	* tag(capture(l.digit ^ 1) / tonumber, "lnum")
	* colon
	* tag(capture(l.digit ^ 1) / tonumber, "col")
	* colon
	* tag(capture(char ^ 0) / vim.trim, "text")
	* linefeed
)

local parsers = {
	mix = mix,
	vimgrep = vimgrep,
}

local filetypes = {
	elixir = {
		mix,
		vimgrep,
	},
	default = {
		mix,
		vimgrep,
	},
}

local M = {}

function M.parser_for_tool(tool)
	local parser = parsers[tool]
	return to_table((parser + rest_of_line) ^ 0)
end

function M.parser_for_filetype(filetype)
	local rules = filetypes[filetype] or filetypes.default

	local parser = nil

	for _, rule in ipairs(rules) do
		if parser == nil then
			parser = rule
		else
			parser = parser + rule
		end
	end

	return to_table((parser + rest_of_line) ^ 0)
end

return M
