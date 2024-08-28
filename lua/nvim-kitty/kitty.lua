local M = {}

local format = string.format

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

		local w = {}
		w.text = text

		if #win.foreground_processes > 0 then
			w.cwd = win.foreground_processes[1].cwd
		else
			w.cwd = win.cwd
		end

		wins[idx] = w
	end

	return wins
end

function M.get_diagnostics_for_text(parser, cwd, text)
	local diagnostics = {}

	local matches = parser:match(text)

	for _, match in ipairs(matches) do
		if vim.fn.filereadable(cwd .. "/" .. match.path) == 1 then
			table.insert(diagnostics, {
				text = match.text,
				severity = match.severity,
				path = match.path,
				lnum = match.lnum or 0,
				cwd = cwd,
				col = match.col or 0,
			})
		end
	end

	local out = unique_by(diagnostics, function(v)
		return v.path .. v.lnum .. v.text
	end)

	return out
end

function M.get_diagnostics()
	local diagnostics = {}
	local ft = vim.bo.filetype
	local parser = require("nvim-kitty.parsers").parser_for_filetype(ft)

	for _, win in ipairs(M.get_text()) do
		local matches = parser:match(win.text)

		for _, match in ipairs(matches) do
			assert(type(match) == "table", "Match must be a table")
			assert(type(match.path) == "string", "Match.path must be a string")
			assert(type(match.text or "") == "string", "Match.text must be a string")
			assert(type(match.lnum or 0) == "number", "Match.lnum must be a number")
			assert(type(match.col or 0) == "number", "Match.col must be a number")
			assert(type(match.severity or vim.diagnostic.severity.ERROR) == "number", "Match.severity must be a number")
			vim.print(vim.inspect(match.path))

			local path = match.path

			if path == nil then
				path = ""
			end

			if vim.fn.filereadable(path) ~= 1 then
				path = win.cwd .. "/" .. path

				if vim.fn.filereadable(path) ~= 1 then
					goto continue
				end
			end

			table.insert(diagnostics, {
				text = match.text or "",
				severity = match.severity or vim.diagnostic.severity.ERROR,
				path = path,
				lnum = match.lnum or 0,
				cwd = win.cwd,
				col = match.col or 0,
			})

			::continue::
		end
	end

	local out = unique_by(diagnostics, function(v)
		return v.path .. v.lnum .. v.text
	end)

	return out
end

function M.get_diagnostics_for_parser(parser)
	local diagnostics = {}
	for _, win in ipairs(M.get_text()) do
		local matches = parser:match(win.text)

		for _, match in ipairs(matches) do
			table.insert(diagnostics, {
				text = match.text or "",
				severity = match.severity or vim.diagnostic.severity.ERROR,
				path = match.path,
				lnum = match.lnum or 0,
				cwd = win.cwd,
				col = match.col or 0,
			})
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
			matches = matches,
		})
	end

	vim.print(vim.inspect(out))
end

function M.info()
	local ft = vim.bo.filetype
	local filetypes = require("nvim-kitty.parsers").filetypes

	local parsers = filetypes[ft] or filetypes.default

	local out = {
		ft = ft,
		parsers = parsers,
	}

	vim.print(vim.inspect(out))
end

return M
