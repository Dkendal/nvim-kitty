local h = require("nvim-kitty.parsers.helper")

local parser = h.to_table(h.location * h.colon * h.group(h.capture(h.char ^ 0) / vim.trim, "text") * h.linefeed)

return parser
