local lpeg = require("lpeglabel")
local l = {}
lpeg.locale(l)

local string = lpeg.P
local capture = lpeg.C
local tag = lpeg.Cg
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
local take_while_not_followed_by1 = helper.take_while_not_followed_by1
local optional = helper.optional
local flatten = helper.flatten

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

local mix_test_stacktrace = h.to_table(
	h.string("       ")
	* h.tag((("(" * (h.char - ")") ^ 1 * ")") ^ 0), "module")
	* h.path
	* h.colon
	* h.tag(h.capture(l.digit ^ 1) / tonumber, "lnum")
	* h.colon
	* h.tag(h.capture(char ^ 1) / vim.trim, "text")
) / h.set_tag("severity", vim.diagnostic.severity.ERROR)

local indent2 = string("     ")

local mix_test = to_table(
	    ("  " * tag(capture(text) / vim.trim, "test_name") * linefeed)
	    * (indent2 * path * colon * tag(capture(repeat1(l.digit)) / tonumber, "lnum") * linefeed)
	    * (indent2 * tag(capture(take_while_not_followed_by1(string("\n     code:"))) / vim.trim, "text"))
	    * optional( --
		    linefeed
		    * (indent2 * "code:" * rest_of_line)
		    * optional(                --
			    (indent2 * "left:" * rest_of_line) --
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
	    for _index, value in ipairs(tbl[1]) do
		    value.text = tbl.test_name .. "\n\t" .. value.text
	    end
	    return tbl
    end
    / flatten

return mix_test + mix_test_stacktrace + mix_compile_error + mix_error + mix_warning
