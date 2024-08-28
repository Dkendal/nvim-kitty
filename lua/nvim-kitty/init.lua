local M = {}

function M.setup(_opts)
	vim.api.nvim_create_user_command("KittyPaths",
		function()
			require("nvim-kitty.telescope").finder()
		end,
		{
			force = true,
		})

	vim.api.nvim_create_user_command("KittyInfo", require("nvim-kitty.kitty").info, { force = true })

	vim.keymap.set("n", "<plug>(kitty-paths)", ":KittyPaths<CR>", { noremap = true, silent = true })
end

return M
