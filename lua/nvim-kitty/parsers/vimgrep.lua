local lpeg = require("lpeglabel")
local l = {}
lpeg.locale(l)

local h = require("nvim-kitty.parsers.helper")

local parser = h.to_table(
	h.path
	* h.colon
	* h.tag(h.capture(l.digit ^ 1) / tonumber, "lnum")
	* h.colon
	* h.tag(h.capture(l.digit ^ 1) / tonumber, "col")
	* h.colon
	* h.tag(h.capture(h.char ^ 0) / vim.trim, "text")
	* h.linefeed
)

return parser
