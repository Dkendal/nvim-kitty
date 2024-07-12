local h = require("nvim-kitty.parsers.helper")

local parser = (1 - (h.set("[") + h.location)) ^ 0 * h.location

return h.to_table(parser)
