return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('telescope').setup({})

    local builtin = require('telescope.builtin')
    -- Твой новый ультимативный поиск по буферам и файлам:
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Поиск файлов' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Поиск текста' })
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Список буферов' })
  end
}

