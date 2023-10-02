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
--
function M.get_text()
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

	local wins = {}

	for idx, win in ipairs(other_windows) do
		local cmd = format("kitty @ get-text --match id:%s --extent screen", win.id)
		local text = vim.fn.system(cmd)

		vim.print(vim.inspect(win))

		wins[idx] = {
			text = text,
			cwd = win.cwd,
			processes = win.foreground_processes,
		}
	end

	return wins
end

function M.get_diagnostics()
	local diagnostics = {}
	local ft = vim.bo.filetype
	local parser = require("nvim-kitty.parsers").parser_for_filetype(ft)

	for _, win in ipairs(M.get_text()) do
		local matches = parser:match(win.text)

		for _, match in ipairs(matches) do
			if vim.fn.filereadable(match.path) == 1 then
				table.insert(diagnostics, {
					text = match.text,
					path = match.path,
					lnum = match.lnum,
					cwd = win.cwd,
					col = match.col or 0,
				})
			end
		end
	end
	return diagnostics
end

vim.g.nvim_kitty = vim.g.nvim_kitty or {}

if not vim.g.nvim_kitty.loaded then
	vim.g.nvim_kitty.loaded = true

	vim.api.nvim_create_user_command("KittyPaths", require("nvim-kitty.telescope").finder, {
		force = true,
	})
end

return M
