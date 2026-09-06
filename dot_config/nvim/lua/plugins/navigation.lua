return {
  {
    'stevearc/oil.nvim',
    lazy = false,
    opts = {
      view_options = { show_hidden = true },
      keymaps = {
        ['<leader>p'] = {
          callback = function()
            local path = require('oil').get_current_dir()
            if path then
              vim.fn.setreg('+', path)
              vim.notify('Copied: ' .. path)
            end
          end,
          desc = 'Copy full path',
        },
        ['<leader>i'] = {
          callback = function()
            local dir = require('oil').get_current_dir()
            if not dir then return end
            local git_dir = vim.fs.find('.git', { upward = true, path = dir })[1]
            local root = git_dir and vim.fs.dirname(git_dir) or dir
            vim.system({
              'sh', '-c',
              'git -C "$1" log -1 --oneline --decorate && git -C "$1" status -sb -uno',
              '--', root,
            }, {}, function(out)
              vim.schedule(function()
                vim.notify(out.stdout ~= '' and out.stdout or (out.stderr or 'not a git repo'),
                  out.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
              end)
            end)
          end,
          desc = 'Git info (HEAD + ahead/behind)',
        },
      },
    },
    keys = { { '<leader>e', '<cmd>Oil<cr>', desc = 'File Browser' } },
  },
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      picker = { enabled = true },
      notifier = { enabled = true },
      input = { enabled = true },
    },
    keys = {
      { '<leader>f', function() Snacks.picker.files() end, desc = 'Find Files' },
      { '<leader>s', function() Snacks.picker.grep() end,  desc = 'Search Text' },
      { '<leader>b', function() Snacks.picker.buffers() end, desc = 'Buffers' },
      {
        '<leader>d',
        function()
          Snacks.picker({
            finder = 'proc',
            cmd = 'fd',
            args = { '--type', 'd', '--color', 'never', '--strip-cwd-prefix', '-E', '.git' },
            format = 'file',
            title = 'Find Dirs',
            transform = function(item, ctx)
              item.file = vim.fs.normalize(ctx.picker:cwd() .. '/' .. item.text)
              item.dir = true
              return item
            end,
            confirm = function(picker, item)
              picker:close()
              vim.cmd('edit ' .. vim.fn.fnameescape(item.file))
            end,
          })
        end,
        desc = 'Find Dirs',
      },
      {
        'gd',
        function()
          -- Use the LSP definition provider when a client that supports it is
          -- attached to this buffer (e.g. jdtls for Java). Otherwise fall back
          -- to a project-wide grep for the word under the cursor.
          -- This matters for Kotlin on large gradle monorepos where
          -- kotlin-language-server cannot finish initializing (it needs a
          -- `kotlinLSPProjectDeps` gradle task that the project doesn't ship),
          -- so gd would otherwise always be empty there.
          local use_lsp = false
          for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
            if c.server_capabilities.definitionProvider then
              use_lsp = true
              break
            end
          end
          if use_lsp then
            Snacks.picker.lsp_definitions()
          else
            Snacks.picker.grep({ search = vim.fn.expand('<cword>') })
          end
        end,
        desc = 'Goto Definition',
      },
    },
  },
}

