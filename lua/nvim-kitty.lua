local M = {}

vim.g.nvim_kitty = vim.g.nvim_kitty or {}

if not vim.g.nvim_kitty.loaded then
	vim.g.nvim_kitty.loaded = true

	vim.api.nvim_create_user_command("KittyPaths", require("nvim-kitty.telescope").finder, {
		force = true,
	})
end

return M
