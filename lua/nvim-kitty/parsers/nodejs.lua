local lpeg = require("lpeglabel")
local l = {}
lpeg.locale(l)

local h = require("nvim-kitty.parsers.helper")

local trace_header = h.to_table(
    h.string("Trace: ") * h.group(h.capture(h.rest_of_line) / vim.trim, "text")
)

local internal_path = h.group(h.capture(h.string("node:") * (h.char - h.set(": ")) ^ 1) / vim.trim, "path")

local stack_entry = h.to_table(
        h.ws_
        * h.string("at")
        * h.ws_
        * h.group(h.capture(h.while_not1(h.string(" ("))), "module")
        * h.ws_
        * h.string("(")
        * (internal_path + h.path)
        * h.colon
        * h.lnum
        * h.colon
        * h.col
        * h.string(")")
        * h.linefeed
    )
    / h.set_tag("type", vim.diagnostic.severity.INFO)

local stack_entry_no_module = h.to_table(
        h.ws_
        * h.string("at")
        * h.ws_
        * (internal_path + h.path)
        * h.colon
        * h.lnum
        * h.colon
        * h.col
        * h.linefeed
    )
    / h.set_tag("type", vim.diagnostic.severity.INFO)

local nodejs_parser = h.to_table(
        trace_header * h.repeat1(stack_entry + stack_entry_no_module)
    )
    / function(tbl)
        local text = tbl[1].text
        for i = 2, #tbl do
            tbl[i].text = text
        end
        return vim.fn.slice(tbl, 1, #tbl)
    end
    / h.flatten

return nodejs_parser
