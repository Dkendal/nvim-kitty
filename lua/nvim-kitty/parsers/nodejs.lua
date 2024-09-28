local h = require("nvim-kitty.parsers.helper")

local nodejs_stacktrace_parser2 = h.to_table(h.ws * h.string("at ") * h.location)
	/ h.set_tag("type", vim.diagnostic.severity.ERROR)
	/ h.set_tag("text", "nodejs stacktrace")

local nodejs_stacktrace_parser = h.to_table(
	h.ws
		* h.string("at ")
		* h.group(h.capture(h.while_not1(h.string("("))) / vim.trim, "text")
		* h.location
		* h.string(")")
		* h.linefeed
) / h.set_tag("type", vim.diagnostic.severity.ERROR)

return nodejs_stacktrace_parser
