local h = require("nvim-kitty.parsers.helper")

local error_class = (h.string("error") + h.string("warning") + h.string("hint"))
local severity = h.group(error_class / h.error_type, "severity")

local path_pattern = h.ws * h.string("-->") * h.ws * h.location

local parser = h.to_table(
	severity
	* (1 - h.colon) ^ 0 -- ignore everything until the first colon
	* h.colon
	* h.group(h.capture(h.rest_of_line) / vim.trim, "text")
	* path_pattern
)

return parser
