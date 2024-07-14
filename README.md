# Nvim-Kitty

Neovim plugin to pull paths, quickfix data from another [kitty terminal](https://sw.kovidgoyal.net/kitty/) split.

![image](https://github.com/user-attachments/assets/8fba3157-e9a0-4f48-a145-6939b20ee72b)

# Installation

Using [vim-plug](https://github.com/junegunn/vim-plug)

```viml
Plug 'dkendal/nvim-kitty'
```

Using [dein](https://github.com/Shougo/dein.vim)

```viml
call dein#add('dkendal/nvim-kitty')
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { 'dkendal/nvim-kitty' }
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- init.lua:
require('lazy').setup({
    -- ...
    {
        'dkendal/nvim-kitty',
	dependencies = {
		"nvim-telescope/telescope.nvim",
	},
	opts = {},
	maps = {
	    { "<leader>pq", "<plug>(kitty-paths)" }
	}
    }
}, opts)
```

# Usage

Nvim-kitty provides a telescope plugin to select a path from the kitty terminal.
There is an API that you can use to build your own UI if you wish.

## Integrations

### Telescope

You can enable the telescope plugin by running:

```lua

require("telescope").load_extension("kitty")

```

Then you can use the `:Telescope kitty` command to open the telescope picker.

### Null-ls

Adds diagnostics from the nearest kitty window.

```lua
require("null-ls").setup({
	sources = {
	    require("nvim-kitty.null-ls")
	}
})
```

# Keybindings

There are no default keybindings, instead bind the provided plug mappings to your liking.

```lua
-- Requires telescope (not the extension though)
vim.keymap.set("n", "<leader>pq", "<plug>(kitty-paths)", { noremap = true, silent = true })
```

# Commands

- `:KittyPaths` - Open the telescope picker to select a path from the kitty terminal.

- `:KittyInfo` - Print diagnostic information, current filetype, available parsers, etc.

# Available Parsers

- rust
    - cargo
- elixir
    - mix
- vimgrep (grep, ripgrep, ag, etc)
- generic (for any tool that outputs a list of paths)

# Contributing

Don't see a parser for your tool or laguage? Feel free to open a PR or issue.

Use one of the existing parsers from ./lua/nvim-kitty/parsers/ as a template and register it in ./lua/nvim-kitty/parsers/init.lua.
