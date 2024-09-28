local M = {}

function M.setup(opts)
	-- vim.api.nvim_create_user_command("KittyPaths", require("nvim-kitty.telescope").finder, {
	-- 	force = true,
	-- })
	--
	-- vim.api.nvim_create_user_command("KittyInfo", require("nvim-kitty.kitty").info, { force = true })
	--
	vim.keymap.set("n", "<plug>(kitty-paths)", ":KittyPaths<CR>", { noremap = true, silent = true })

	if opts.snacks == true then
		require("nvim-kitty.snacks").setup({})
	end
end

return M
