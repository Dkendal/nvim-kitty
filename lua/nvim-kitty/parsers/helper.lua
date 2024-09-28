local M = {}

local lpeg = require("lpeglabel")

M.locale = {}

lpeg.locale(M.locale)

local l = M.locale

M.string = lpeg.P
M.set = lpeg.S
M.range = lpeg.R
M.capture = lpeg.C
M.group = lpeg.Cg
M.pos = lpeg.Cp
M.sub = lpeg.Cs
M.match_time = lpeg.Cmt
M.to_table = lpeg.Ct
M.linefeed = M.string("\n") + M.string("\r\n")
M.ws = M.set(" \t\r\n") ^ 0
M.ws_ = M.set(" \t") ^ 0
M.tab = M.string("\t")
M.quote = M.string([[']])
M.dquote = M.string([["]])

function M.dbg(t)
	vim.print(vim.inspect(t))
	return t
end

local function cast_string(p)
	if type(p) == "string" then
		p = M.string(p)
	end
	return p
end

function M.ignore(p)
	p = cast_string(p)
	return M.capture(p) / ""
end

function M.optional(p)
	p = cast_string(p)
	return p ^ -1
end

function M.repeat1(p)
	p = cast_string(p)
	return p ^ 1
end

function M.repeat0(p)
	p = cast_string(p)
	return p ^ 0
end

function M.while_not1(p)
	p = cast_string(p)
	return (1 - p) ^ 1
end

--- Convert an error string to a severity level
--- @param str string
--- @return integer
function M.error_type(str)
	str = str:lower()

	if str == "error" then
		return vim.diagnostic.severity.ERROR
	elseif str == "warning" then
		return vim.diagnostic.severity.WARN
	elseif str == "info" then
		return vim.diagnostic.severity.INFO
	elseif str == "note" then
		return vim.diagnostic.severity.HINT
	elseif str == "hint" then
		return vim.diagnostic.severity.HINT
	end

	error("Unknown error type: " .. str)
end

M.linefeed = M.string("\n") + M.string("\r\n")
M.ws = M.set(" \t") ^ 0
M.tab = M.string("\t")
M.char = (1 - M.linefeed)
M.colon = M.string(":")

-- Path components
local slash = M.string("/")
local dot = M.string(".")
local dotdot = M.string("..")
local name = (M.range("az", "AZ") + M.range("09") + M.set("_-")) ^ 1
local extension = dot * name

-- Path pattern
local dir = ((dot + dotdot + name) * slash)
local filename = name * extension
local path = slash ^ -1 * dir ^ 0 * filename

M.path = M.group(M.capture(path) / vim.trim, "path")

M.number = M.capture(l.digit ^ 1) / tonumber
M.lnum = M.group(M.number, "lnum")
M.col = M.group(M.number, "col")
M.location = M.path * M.colon * M.lnum * M.colon * M.col
M.rest_of_line = M.char ^ 0 * M.linefeed
M.text = M.char ^ 1

function M.flatten(tbl, _key)
	local sub = {}

	if tbl.path then
		table.insert(sub, tbl)
	end

	for index, value in ipairs(tbl) do
		tbl[index] = nil

		if type(value) == "table" then
			vim.list_extend(sub, { M.flatten(value) })
		else
			table.insert(sub, value)
		end
	end

	return unpack(sub)
end

function M.debug(tbl)
	vim.print(vim.inspect(tbl))
	return tbl
end

function M.set_tag(key, value)
	return function(tbl)
		tbl[key] = value
		return tbl
	end
end

return M
