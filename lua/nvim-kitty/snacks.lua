local M = {}

local function get_kitty_items()
	local kitty = require("nvim-kitty.kitty")
	local diagnostics = kitty.get_diagnostics()
	local items = {}

	for _, diagnostic in ipairs(diagnostics) do
		-- Format file path for display
		local display_path = string.format("%s:%s:%s", diagnostic.path, diagnostic.lnum, diagnostic.col)

		-- Create a preview file path - use only the cwd if it exists
		local preview_file
		if vim.fn.isdirectory(diagnostic.cwd) == 1 then
			if vim.startswith(diagnostic.path, "/") then
				preview_file = diagnostic.path -- Use absolute path directly
			else
				preview_file = diagnostic.cwd .. "/" .. diagnostic.path
			end

			-- Make sure the file exists
			if vim.fn.filereadable(preview_file) ~= 1 then
				preview_file = nil
			end
		end

		-- Create a picker item without including paths that will be automatically combined
		local item = {
			value = diagnostic,
			text = diagnostic.text,
			lnum = diagnostic.lnum,
			col = diagnostic.col,
			severity = diagnostic.severity,
			display_path = display_path,
		}

		-- Only add file properties if the preview file exists
		if preview_file then
			item.preview_file = preview_file
			item.file = preview_file -- Add the file property that snacks.nvim expects for preview

			-- Add proper locator information for snacks.nvim preview
			if diagnostic.lnum and diagnostic.lnum > 0 then
				-- Based on snacks.nvim's code, it uses these properties for location:
				item.lnum = diagnostic.lnum -- Line number (1-based)
				item.col = diagnostic.col or 0 -- Column number

				-- Convert 1-based line to 0-based for LSP format
				local zero_line = diagnostic.lnum - 1

				-- Add properly formatted LSP-style loc property for snacks.picker.util.resolve_loc
				-- This matches what snacks expects in its resolve_loc function
				item.loc = {
					range = {
						["start"] = {
							line = zero_line,
							character = diagnostic.col or 0,
						},
						["end"] = {
							line = zero_line,
							character = (diagnostic.col or 0) + 1,
						},
					},
					encoding = "utf-16",
					resolved = false,
				}
			end
		end

		table.insert(items, item)
	end

	return items
end

function M.setup()
	local picker = require("snacks.picker")

	-- Add custom actions
	picker.actions = picker.actions or {}

	-- picker.actions.kitty_open = function(pick)
	-- 	local item = pick:current()
	-- 	if item and item.preview_file then
	-- 		-- Open the file at the specific line and column
	-- 		vim.cmd(string.format("edit +%d %s", item.lnum, item.preview_file))
	-- 		if item.col > 0 then
	-- 			vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
	-- 		end
	-- 		pick:close()
	-- 	end
	-- end

	-- Add formatter if the API supports it
	if picker.format and type(picker.format.add) == "function" then
		picker.format.add("kitty", function(item)
			-- Severity icon and highlight - using more distinctive icons
			local severity_icon = ""
			local severity_hl = "Normal"

			-- Map severity to icons and highlights
			if item.severity == vim.diagnostic.severity.ERROR then
				severity_icon = "󰅚 " -- Error icon
				severity_hl = "DiagnosticError"
			elseif item.severity == vim.diagnostic.severity.WARN then
				severity_icon = "󰀦 " -- Warning icon
				severity_hl = "DiagnosticWarn"
			elseif item.severity == vim.diagnostic.severity.INFO then
				severity_icon = "󰋽 " -- Info icon
				severity_hl = "DiagnosticInfo"
			elseif item.severity == vim.diagnostic.severity.HINT then
				severity_icon = "󰌶 " -- Hint/lightbulb icon
				severity_hl = "DiagnosticHint"
			end

			-- Get a devicon for the file type
			local devicons_available = pcall(require, "nvim-web-devicons")
			local icon = ""
			local icon_hl = "Normal"

			if devicons_available and item.file then
				local file_ext = vim.fn.fnamemodify(item.file, ":e")
				local filename = vim.fn.fnamemodify(item.file, ":t")
				local devicons = require("nvim-web-devicons")

				-- Try to get an icon based on the file extension or name
				local file_icon, _color = devicons.get_icon(filename, file_ext, { default = true })
				if file_icon then
					icon = file_icon .. " "
					icon_hl = "DevIcon" .. file_ext:gsub("%W", "_"):gsub("^%l", string.upper)
				end
			end

			return {
				{ severity_icon,     severity_hl },
				{ icon,              icon_hl },
				{ item.display_path, "Comment" },
				{ " ",               "Normal" },
				{ item.text or "",   "Normal" },
			}
		end)
	end
end

-- Create a simple formatter function instead of using the registered one
local function format_item(item)
	-- Severity icon and highlight - using more distinctive icons
	local severity_icon = ""
	local severity_hl = "Normal"

	-- Map severity to icons and highlights
	if item.severity == vim.diagnostic.severity.ERROR then
		severity_icon = "󰅚 " -- Error icon
		severity_hl = "DiagnosticError"
	elseif item.severity == vim.diagnostic.severity.WARN then
		severity_icon = "󰀦 " -- Warning icon
		severity_hl = "DiagnosticWarn"
	elseif item.severity == vim.diagnostic.severity.INFO then
		severity_icon = "󰋽 " -- Info icon
		severity_hl = "DiagnosticInfo"
	elseif item.severity == vim.diagnostic.severity.HINT then
		severity_icon = "󰌶 " -- Hint/lightbulb icon
		severity_hl = "DiagnosticHint"
	end

	-- Get a devicon for the file type
	local devicons_available = pcall(require, "nvim-web-devicons")
	local icon = ""
	local icon_hl = "Normal"

	if devicons_available and item.file then
		local file_ext = vim.fn.fnamemodify(item.file, ":e")
		local filename = vim.fn.fnamemodify(item.file, ":t")
		local devicons = require("nvim-web-devicons")

		-- Try to get an icon based on the file extension or name
		local file_icon, _color = devicons.get_icon(filename, file_ext, { default = true })
		if file_icon then
			icon = file_icon .. " "
			icon_hl = "DevIcon" .. file_ext:gsub("%W", "_"):gsub("^%l", string.upper)
		end
	end

	return {
		{ severity_icon,     severity_hl },
		{ icon,              icon_hl },
		{ item.display_path, "Comment" },
		{ " ",               "Normal" },
		{ item.text or "",   "Normal" },
	}
end

-- Public picker function
function M.picker(opts)
	opts = opts or {}

	-- Get the items
	local items = get_kitty_items()

	-- Create picker with items directly
	return require("snacks.picker")({
		items = items,
		title = "Kitty Diagnostics",
		format = format_item, -- Use our inline formatter function
	})
end

return M
