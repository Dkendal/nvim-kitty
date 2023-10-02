local kitty = require("nvim-kitty.kitty")
local M = {}

local null_ls = require("null-ls")

local function severity(error_type)
	if "e" == error_type then
		return vim.diagnostic.severity.ERROR
	elseif "w" == error_type then
		return vim.diagnostic.severity.WARN
	elseif "i" == error_type then
		return vim.diagnostic.severity.INFO
	elseif "n" == error_type then
		return vim.diagnostic.severity.HINT
	end
end

M.diagnostics = {
	method = null_ls.methods.DIAGNOSTICS,
	filetypes = { "elixir" },
	generator = {
		fn = function(params)
			local diagnostics = {}

			for _, line in ipairs(kitty.get_diagnostics()) do
				if vim.fn.bufnr(line.path) == params.bufnr then
					table.insert(diagnostics, {
						row = line.lnum,
						source = "kitty",
						message = "🐱 " .. line.text,
						severity = severity(line.error_type) or vim.diagnostic.severity.HINT,
					})
				end
			end

			return diagnostics
		end,
	},
}
return M
