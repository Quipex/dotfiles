return {
  {
    'NeogitOrg/neogit',
    dependencies = { 'nvim-lua/plenary.nvim', 'sindrets/diffview.nvim' },
    keys = {
      {
        '<leader>g',
        function()
          local path = vim.fn.expand('%:p')
          local cwd
          if vim.fn.isdirectory(path) == 1 then
            cwd = path
          elseif vim.bo.filetype == 'oil' then
            local dir = require('oil').get_current_dir()
            local entry = require('oil').get_cursor_entry()
            if entry and entry.type == 'directory' and dir then
              cwd = vim.fs.joinpath(dir, entry.name)
            else
              cwd = dir
            end
          end
          require('neogit').open(cwd and { cwd = cwd } or nil)
        end,
        desc = 'Neogit',
      },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufWinEnter',
    opts = { current_line_blame = true },  -- who last touched this line
  },
}

