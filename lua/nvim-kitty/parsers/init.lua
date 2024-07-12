local lpeg = require("lpeglabel")
local to_table = lpeg.Ct
local helper = require("nvim-kitty.parsers.helper")
local rest_of_line = helper.rest_of_line

local parsers = {
	vimgrep = require("nvim-kitty.parsers.vimgrep"),
	mix = require("nvim-kitty.parsers.mix"),
	cargo = require("nvim-kitty.parsers.cargo"),
	generic = require("nvim-kitty.parsers.generic"),
}

local filetypes = {
	elixir = {
		mix = parsers.mix,
		vimgrep = parsers.vimgrep,
	},
	rust = {
		cargo = parsers.cargo,
	},
	default = {
		vimgrep = parsers.vimgrep,
		generic = parsers.generic,
	},
}

local M = {}

M.filetypes = filetypes

---@param tool string
---@return table
function M.parser_for_tool(tool)
	local parser = parsers[tool]
	return to_table((parser + rest_of_line) ^ 0)
end

---@param filetype string
---@return table
function M.parser_for_filetype(filetype)
	local rules = filetypes[filetype] or filetypes.default

	local parser = nil

	for _, rule in pairs(rules) do
		if parser == nil then
			parser = rule
		else
			parser = parser + rule
		end
	end

	return M.wrap(parser)
end

---@param parser table
---@return table
function M.wrap(parser)
	return to_table((parser + rest_of_line) ^ 0)
end

return M
