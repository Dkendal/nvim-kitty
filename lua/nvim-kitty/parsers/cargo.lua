local h = require("nvim-kitty.parsers.helper")

local error_class = (h.string("error") + h.string("warning") + h.string("hint"))
local severity = h.group(error_class / h.error_type, "severity")

local path_pattern = h.ws * h.string("-->") * h.ws * h.location

local cargo_parser = h.to_table(
	severity
	* (1 - h.colon) ^ 0 -- ignore everything until the first colon
	* h.colon
	* h.group(h.capture(h.rest_of_line) / vim.trim, "text")
	* path_pattern
)

local thread_info = h.string("thread")
		* h.ws
		* h.quote
		* h.while_not1(h.quote)
		* h.quote
		* h.ws
		* h.string("panicked at")
		* h.ws

local location = h.group(h.path, "path") * h.colon * h.group(h.number, "lnum") * h.colon * h.group(h.number, "col")
local text = h.group(h.rest_of_line / vim.trim, "text")

local rust_panic_parser = h.to_table(thread_info * location * h.ws * h.colon * h.rest_of_line * text)
		/ h.set_tag("severity", vim.diagnostic.severity.ERROR)

local entry_number = h.ws * h.group(h.capture(h.number), "stack_number") * h.string(":") * h.ws

local function_name = h.group(h.rest_of_line, "text")

local path_info = h.ws * h.string("at") * h.ws * h.location * h.rest_of_line

local single_entry = h.to_table(entry_number * function_name * path_info)
		/ function(entry)
			return vim.tbl_extend("force", entry, {
				severity = vim.diagnostic.severity.ERROR,
				text = string.format("%s: %s", entry.stack_number, entry.text),
			})
		end

local rust_backtrace_parser = h.to_table(h.string("stack backtrace:") * h.linefeed * h.repeat1(single_entry)) / unpack

return cargo_parser + rust_panic_parser + rust_backtrace_parser
