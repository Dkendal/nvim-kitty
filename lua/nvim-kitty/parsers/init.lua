local lpeg = require("lpeglabel")
local to_table = lpeg.Ct
local helper = require("nvim-kitty.parsers.helper")
local rest_of_line = helper.rest_of_line

local vimgrep = require("nvim-kitty.parsers.vimgrep")
local mix = require("nvim-kitty.parsers.mix")
local cargo = require("nvim-kitty.parsers.cargo")

local parsers = {
	mix = mix,
	vimgrep = vimgrep,
	cargo = cargo,
}

local filetypes = {
	elixir = {
		mix,
		vimgrep,
	},
	rust = {
		cargo,
	},
	default = {
		mix,
		vimgrep,
	},
}

local M = {}

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

	for _, rule in ipairs(rules) do
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
