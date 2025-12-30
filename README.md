# run-build.nvim

A simple build runner for Neovim. It saves a project-specific build command to `.run_build/command.txt` and pipes errors into the quickfix list. 

Specifically tuned for languages like Odin that provide multi-line error hints.

## Features
- **Project-specific**: Saves your build command per project directory.
- **Clean Quickfix**: Automatically strips Windows `^M` carriage returns from output.
- **Smart Formatting**: Captures multi-line error context (code snippets/carets) but marks them as "invalid" items so `:cnext` skips them correctly.
- **Flexible output**: Run silently in the background or in a visible split buffer.

## Installation

```lua
-- lazy.nvim
{
  "cmdl-dev/run-build.nvim",
  config = function()
    require("run_build").setup()
    
    -- Pick your own keymaps
    vim.keymap.set('n', '<leader>bs', '<cmd>RunBuildSelect<cr>', { desc = 'Build: Select Command' })
    vim.keymap.set('n', '<leader>br', '<cmd>RunBuildSilent<cr>', { desc = 'Build: Run (Silent)' })
    vim.keymap.set('n', '<leader>bb', '<cmd>RunBuildBuffer<cr>', { desc = 'Build: Run (Buffer)' })
  end
}
```

## Usage

### Commands
- `:RunBuildSelect`: Set the build command (e.g., `odin build .`).
- `:RunBuildSilent`: Runs the command in the background. Opens quickfix if it fails, clears/closes it if it passes.
- `:RunBuildBuffer`: Opens a vertical split showing the live output.

### In-Buffer Keybinds
When using `:RunBuildBuffer`, these are available locally:
- `<Leader>aq`: Filter the current buffer and move error lines to the quickfix list.
- `<Esc>`: Close the output split.

## License
MIT
