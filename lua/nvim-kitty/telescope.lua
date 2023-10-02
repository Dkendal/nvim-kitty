local kitty = require("nvim-kitty.kitty")
local format = string.format

local M = {}

function M.finder()
	local diagnostics = kitty.get_diagnostics()

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions_set = require("telescope.actions.set")
	local actions_state = require("telescope.actions.state")
	local themes = require("telescope.themes")
	local conf = require("telescope.config").values
	local sorters = require("telescope.sorters")

	local opts = themes.get_ivy({})

	pickers
		.new(opts, {
			prompt_title = "Kitty 🐱 - Paths",
			finder = finders.new_table({
				results = diagnostics,
				entry_maker = function(diagnostic)
					local path = format("%s/%s", diagnostic.cwd, diagnostic.path)
					local str = format("%s:%s", path, diagnostic.lnum)

					return {
						value = diagnostic,
						display = diagnostic.text,
						ordinal = str,
						path = format("%s/%s", diagnostic.cwd, diagnostic.path),
						lnum = diagnostic.lnum,
					}
				end,
			}),
			sorter = sorters.get_fzy_sorter(opts),
			previewer = conf.grep_previewer(opts),
		})
		:find()
end

return M
