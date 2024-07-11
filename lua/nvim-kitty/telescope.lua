local kitty = require("nvim-kitty.kitty")
local format = string.format

local M = {}

function M.finder(opts)
	opts = opts or {}

	local diagnostics = kitty.get_diagnostics()

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions_set = require("telescope.actions.set")
	local actions_state = require("telescope.actions.state")
	local themes = require("telescope.themes")
	local conf = require("telescope.config").values
	local sorters = require("telescope.sorters")

	local entry_maker = function(diagnostic)
		local path = format("%s/%s", diagnostic.cwd, diagnostic.path)
		local str = format("%s:%s", path, diagnostic.lnum)

		local severity = diagnostic.severity
		if severity == vim.diagnostic.severity.ERROR then
			severity = "E"
		elseif severity == vim.diagnostic.severity.WARN then
			severity = "W"
		elseif severity == vim.diagnostic.severity.INFO then
			severity = "I"
		elseif severity == vim.diagnostic.severity.HINT then
			severity = "H"
		else
			severity = "E"
		end

		local display = format("[%s] %s:%d: %s", severity, diagnostic.path, diagnostic.lnum, diagnostic.text)

		return {
			value = diagnostic,
			display = display,
			ordinal = str,
			path = format("%s/%s", diagnostic.cwd, diagnostic.path),
			lnum = diagnostic.lnum,
		}
	end

	vim.print(vim.inspect(opts))
	pickers
			.new(opts, {
				prompt_title = "Kitty 🐱 - Paths",
				finder = finders.new_table({
					results = diagnostics,
					entry_maker = entry_maker,
				}),
				sorter = sorters.highlighter_only(opts),
				previewer = conf.grep_previewer(opts),
			})
			:find()
end

return M
