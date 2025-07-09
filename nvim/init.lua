-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

vim.cmd("source ~/.vimrc")

require("config.lazy")

require("nvim-tree").setup({
  actions = {
    open_file = {
      window_picker = {
        enable = false,
      },
    },
  },
})

-- Mimics how nerdtree worked so I can keep SOME of my original workflow
vim.keymap.set("n", "<leader>nt", ":NvimTreeToggle<CR>", { silent = true })

-- Opens nvim-tree on startup if no files are specified
vim.api.nvim_create_autocmd("StdinReadPre", {
  pattern = "*",
  command = "let s:std_in=1",
})

vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  command = [[
    if argc() == 0 && !exists("s:std_in") | NvimTreeOpen | endif
  ]],
})

vim.keymap.set('n', '<leader><space>', function()
  vim.cmd('noh')
  vim.cmd('call clearmatches()')
end, { silent = true })

require("codecompanion").setup({
  strategies = {
    chat = {
      adapter = "copilot",
    },
    inline = {
      adapter = "copilot",
    },
    agent = {
      adapter = "copilot",
    },
  },
})
