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

--- @param str string
--- @return string
local function error_type(str)
	str = str:lower()

	if str == "error" then
		return "e"
	elseif str == "warning" then
		return "w"
	elseif str == "info" then
		return "i"
	elseif str == "note" then
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

local mix = nil

do
	local mix_error_detail = (
		tab
		* tag(capture((any - string(":")) ^ 0), "path")
		* colon
		* tag(capture(l.digit ^ 1) / tonumber, "lnum")
		* colon
		* tag(capture(any ^ 0) / vim.trim, "module")
	)

	local mix_error = to_table(
		tag(string("error") / error_type, "type")
			* colon
			* tag(capture(any ^ 1) / vim.trim, "text")
			* lf
			* mix_error_detail
			* lf
	)

	local mix_warning = to_table(
		tag(string("warning") / error_type, "type")
			* colon
			* tag(capture(any ^ 1) / vim.trim, "text")
			* lf
			* mix_error_detail
			* lf
	)

	local mix_compile_error = to_table(
		string("** (CompileError) ")
			* tag(capture((any - string(":")) ^ 0), "path")
			* colon
			* tag(capture(any ^ 0) / vim.trim, "text")
	)

	mix = mix_compile_error + mix_error + mix_warning
end

local vimgrep = to_table(
	tag(capture((any - string(":")) ^ 0), "path")
		* colon
		* tag(capture(l.digit ^ 1) / tonumber, "lnum")
		* colon
		* tag(capture(l.digit ^ 1) / tonumber, "col")
		* colon
		* tag(capture(any ^ 0) / vim.trim, "text")
		* lf
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
		vimgrep,
	},
}

local M = {}

function M.parser_for_tool(tool)
	local parser = parsers[tool]
	return to_table((parser + line) ^ 0)
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

	return to_table((parser + line) ^ 0)
end

-- parser = to_table(mix + line) ^ 0,

return M
