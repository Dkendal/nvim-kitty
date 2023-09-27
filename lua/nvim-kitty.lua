local M = {}

local a = require("nvim-kitty.async")
local format = string.format

local path_pattern = "([^%s:]+%.[^%s:]+):(%d+)"

local pid = vim.fn.getpid()

---@class KittyProcess
---@field pid number
---@field cmdline string[]
---@field cwd string

---@class KittyWindow
---@field id number
---@field pid number
---@field lines number
---@field is_active boolean
---@field title boolean
---@field is_focused boolean
---@field is_self boolean
---@field cwd string
---@field foreground_processes KittyProcess[]

---@class KittyTab
---@field id number
---@field is_focused boolean
---@field windows KittyWindow[]

---@class KittyWM
---@field id number
---@field is_focused boolean
---@field tabs KittyTab[]

---@alias KittyState KittyWM[]

---@class SystemResult
---@field stdout string
---@field stderr string
---@field status number

function M.get_diagnostics()
	local out = vim.fn.system("kitty @ ls")

	---@type KittyState
	local json = vim.json.decode(out)

	---@type KittyWindow[]
	local other_windows = {}

	for _, wm in ipairs(json) do
		if wm.is_focused then
			for _, tab in ipairs(wm.tabs) do
				if tab.is_focused then
					for _, win in ipairs(tab.windows) do
						if not win.is_focused then
							table.insert(other_windows, win)
						end
					end
				end
			end
		end
	end

	---@type {text: string, path: string, lnum: string, cwd: string, col: number}[]
	local diagnostics = {}

	for _, win in ipairs(other_windows) do
		local cmd = format("kitty @ get-text --match id:%s --extent screen", win.id)

		local text = vim.fn.system(cmd)

		local lines = vim.split(text, "\n")

		for _, line in ipairs(lines) do
			for path, lnum in string.gmatch(line, path_pattern) do
				if vim.fn.filereadable(path) == 1 then
					table.insert(diagnostics, {
						text = line,
						path = path,
						lnum = tonumber(lnum),
						cwd = win.cwd,
						col = 0,
					})
				end
			end
		end
	end

	return diagnostics
end

function M.finder()
	local diagnostics = M.get_diagnostics()

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

local null_ls = require("null-ls")

M.diagnostics = {
	method = null_ls.methods.DIAGNOSTICS,
	filetypes = { "elixir" },
	generator = {
		fn = function(params)
			local diagnostics = {}

			for _, line in ipairs(M.get_diagnostics()) do
				if vim.fn.bufnr(line.path) == params.bufnr then
					table.insert(diagnostics, {
						row = line.lnum,
						source = "kitty",
						message = "🐱 " .. line.text,
						severity = vim.diagnostic.severity.HINT,
					})
				end
			end

			return diagnostics
		end,
	},
}

function M.setup(_)
	vim.api.nvim_create_user_command("KittyPaths", M.finder, {
		force = true,
	})
end

return M
