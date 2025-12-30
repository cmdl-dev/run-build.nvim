# run-build.nvim

A lightweight Neovim plugin to manage, execute, and navigate build commands with integrated quickfix support for Odin (and other similar error formats).

## Features
- **Project-specific commands**: Saves your build command in a `.run_build/command.txt` file in your root directory.
- **Silent Mode**: Run builds in the background; errors are automatically filtered and added to the quickfix list.
- **Buffer Mode**: Run builds in a separate buffer to see full output, with a shortcut to extract errors to the quickfix list.
- **Smart Quickfix**:
  - Automatically strips Windows carriage returns (`^M`).
  - Includes multi-line helper context (code snippets and carets).
  - Skips helper text when using `:cnext` / `:cprev`.
  - Clears/closes the quickfix list on successful builds.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "YOUR_GITHUB_USERNAME/run-build.nvim",
  config = function()
    require("run_build").setup()
    
    -- Optional: set keymaps
    vim.keymap.set('n', '<leader>bs', '<cmd>RunBuildSelect<cr>', { desc = '[B]uild [S]elect' })
    vim.keymap.set('n', '<leader>br', '<cmd>RunBuildSilent<cr>', { desc = '[B]uild [R]un (Silent)' })
    vim.keymap.set('n', '<leader>bb', '<cmd>RunBuildBuffer<cr>', { desc = '[B]uild [B]uffer' })
  end
}
```

## Usage

### Commands
- `:RunBuildSelect`: Set or update the build command for the current project.
- `:RunBuildSilent`: Run the build in the background. If errors occur, the quickfix list opens automatically.
- `:RunBuildBuffer`: Run the build in a vertical split.

### Keybindings (in Build Output buffer)
- `<Leader>aq`: Add errors from the current output buffer to the quickfix list.
- `<Esc>`: Close the output buffer window.

## License
MIT
