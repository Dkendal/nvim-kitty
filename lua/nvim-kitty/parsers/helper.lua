local M = {}

local lpeg = require("lpeglabel")

M.locale = {}

lpeg.locale(M.locale)

M.string = lpeg.P
M.capture = lpeg.C
M.set = lpeg.S
M.range = lpeg.R
M.tag = lpeg.Cg
M.to_table = lpeg.Ct
M.linefeed = M.string("\n") + M.string("\r\n")
M.spc = M.set(" \t") ^ 0
M.tab = M.string("\t")

function M.ignore(p)
	return M.capture(p) / ""
end

function M.optional(p)
	return p ^ -1
end

function M.repeat1(p)
	return p ^ 1
end

function M.repeat0(p)
	return p ^ 0
end

function M.take_while_not_followed_by1(p)
	return (1 - p) ^ 1
end

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
	end

	error("Unknown error type: " .. str)
end

M.linefeed = M.string("\n") + M.string("\r\n")
M.spc = M.set(" \t") ^ 0
M.tab = M.string("\t")
M.char = (1 - M.linefeed)
M.colon = M.string(":")
M.path = M.tag(M.capture((M.char - M.string(":")) ^ 0) / vim.trim, "path")

-- Explain:
-- 1 - lf: match any character except lf
-- ^0: match zero or more times
-- lf: match line feed
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
