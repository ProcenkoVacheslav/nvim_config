
return {
  "tyru/open-browser.vim",
  config = function()
    vim.keymap.set("n", "gx", "<Plug>(openbrowser-smart-search)", { silent = true, desc = "Открыть в браузере" })

    vim.api.nvim_create_user_command('Open', function()
      vim.fn.execute('OpenBrowser ' .. vim.fn.expand('%:p'))
    end, {})

    vim.keymap.set('n', '<Leader>b', ':Open<CR>', { silent = true, desc = "Открыть HTML в браузере" })
  end
}
