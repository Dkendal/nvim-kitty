local kitty = require("nvim-kitty.kitty")
local format = string.format

local M = {}

local function severity_to_text(severity)
	if severity == vim.diagnostic.severity.ERROR then
		return { "E", "DiagnosticError" }
	elseif severity == vim.diagnostic.severity.WARN then
		return { "W", "DiagnosticWarn" }
	elseif severity == vim.diagnostic.severity.INFO then
		return { "I", "DiagnosticInfo" }
	elseif severity == vim.diagnostic.severity.HINT then
		return { "H", "DiagnosticHint" }
	end

	return { "?", "DiagnosticOk" }
end

local function format_ordinal(entry)
	return format("%s/%s:%s", entry.cwd, entry.path, entry.lnum)
end

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
	local entry_display = require("telescope.pickers.entry_display")

	local path_width = 0

	for _, diagnostic in ipairs(diagnostics) do
		diagnostic.display_path = format("%s:%s:%s", diagnostic.path, diagnostic.lnum, diagnostic.col)
		path_width = math.max(path_width, #diagnostic.display_path)
	end

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 1 },
			{ width = path_width },
			{ remaining = true },
		},
	})

	local function make_display(entry)
		return displayer({
			severity_to_text(entry.value.severity),
			{ entry.value.display_path, "Comment" },
			entry.value.text,
		})
	end

	local function entry_maker(diagnostic)
		local path = ""

		if vim.startswith(diagnostic.path, "/") then
			path = format("%s/%s", diagnostic.cwd, diagnostic.path)
		else
			path = diagnostic.path
		end

		local ordinal = format_ordinal(diagnostic)

		return {
			value = diagnostic,
			display = make_display,
			ordinal = ordinal,
			text = diagnostic.text,
			path = path,
			lnum = diagnostic.lnum,
		}
	end

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
