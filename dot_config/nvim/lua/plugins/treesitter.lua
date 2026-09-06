return {
  {
    'nvim-treesitter/nvim-treesitter',
    -- main branch requires Neovim 0.12+ (uses vim.list, nil on 0.11). master is
    -- the locked, backward-compatible branch for 0.11 and keeps the classic
    -- nvim-treesitter.configs API (ensure_installed / highlight / indent).
    branch = 'master',
    lazy = false,
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
        'kotlin', 'groovy', 'java', 'json', 'yaml', 'toml', 'markdown', 'markdown_inline',
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}