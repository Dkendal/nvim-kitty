local M = {}

local a = require("nvim-kitty.async")
local format = string.format

local path_pattern = "([^%s:]+%.[^%s:]+):(%d+)"

local pid = vim.fn.getpid()

local function unique_by(tbl, fn)
	local seen = {}
	local result = {}

	for _, v in ipairs(tbl) do
		local key = fn(v)

		if not seen[key] then
			seen[key] = true
			table.insert(result, v)
		end
	end

	return result
end

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
		wins[idx] = {}
		wins[idx].text = text
		wins[idx].cwd = win.cwd
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
			if vim.fn.filereadable(win.cwd .. "/" .. match.path) == 1 then
				table.insert(diagnostics, {
					text = match.text,
					severity = match.severity,
					path = match.path,
					lnum = match.lnum or 0,
					cwd = win.cwd,
					col = match.col or 0,
				})
			end
		end
	end

	local out = unique_by(diagnostics, function(v)
		return v.path .. v.lnum .. v.text
	end)

	return out
end

function M.pretty_print()
	local ft = vim.bo.filetype
	local parser = require("nvim-kitty.parsers").parser_for_filetype(ft)

	local out = {}

	for _, win in ipairs(M.get_text()) do
		local matches = parser:match(win.text)
		table.insert(out, {
			cwd = win.cwd,
			matches = matches
		})
	end

	vim.print(vim.inspect(out))
end

return M
