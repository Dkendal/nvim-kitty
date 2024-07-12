local lpeg = require("lpeglabel")
local l = {}
lpeg.locale(l)

local string = lpeg.P
local capture = lpeg.C
local tag = lpeg.Cg
local to_table = lpeg.Ct
local helper = require("nvim-kitty.parsers.helper")
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

-- local parser = to_table(
-- 	path
-- 	* colon
-- 	* tag(capture(l.digit ^ 1) / tonumber, "lnum")
-- 	* colon
-- 	* tag(capture(l.digit ^ 1) / tonumber, "col")
-- 	* colon
-- 	* tag(capture(char ^ 0) / vim.trim, "text")
-- 	* linefeed
-- )


return parser
