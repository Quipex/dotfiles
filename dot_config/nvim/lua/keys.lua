-- save by pressing Escape
vim.keymap.set('n', '<Esc>', ':w<CR>', { desc = 'Save' })
-- copy full path of current file to system clipboard
vim.keymap.set('n', '<leader>yp', function()
  local path = vim.fn.expand('%:p')
  vim.fn.setreg('+', path)
  vim.notify('Copied: ' .. path)
end, { desc = 'Copy full path to clipboard' })
-- open URL under cursor in browser
vim.keymap.set('n', 'gx', function()
  local url = vim.fn.expand('<cfile>')
  if url:match('^https?://') then vim.ui.open(url) end
end, { desc = 'Open URL under cursor' })
-- select all
vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select All' })
-- pasting over a selection no longer clobbers your clipboard
vim.cmd([[ xnoremap <expr> p 'pgv"'.v:register.'y' ]])

-- Format current buffer with prettier (md/json/css/...)
vim.keymap.set('n', '<leader>mf', function()
  vim.cmd('%!prettier --stdin-filepath ' .. vim.fn.shellescape(vim.fn.expand('%')))
end, { desc = 'Format file (prettier)' })

-- LSP keymaps: only active in buffers that have an LSP server attached.
-- `gd` (Goto Definition) is already mapped globally in plugins/navigation.lua;
-- the rest are scoped per-buffer here.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspKeymaps', { clear = true }),
  callback = function(event)
    local map = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end
    map('gr', function() Snacks.picker.lsp_references() end, 'References')
    map('gI', function() Snacks.picker.lsp_implementations() end, 'Implementation')
    map('K', vim.lsp.buf.hover, 'Hover')
    map('<leader>rn', vim.lsp.buf.rename, 'Rename')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
  end,
})

