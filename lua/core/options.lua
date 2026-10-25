vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")
vim.g.deprecated = false


vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true


local status_info = require('core.status_info')

_G.MyCustomStatus = status_info.full_statusline
vim.opt.statusline = "%!v:lua.MyCustomStatus()"

-- 1. Таймер обновления статуслайна раз в секунду
local timer = vim.loop.new_timer()
timer:start(0, 1000, vim.schedule_wrap(function()
  vim.cmd('redrawstatus')
end))

-- 2. Автокоманды мгновенной перерисовки при вводе и изменении диагностик LSP
vim.api.nvim_create_autocmd({ "ModeChanged", "TextChanged", "TextChangedI", "DiagnosticChanged", "CursorMoved", "CursorMovedI" }, {
  pattern = "*",
  callback = function()
    vim.cmd('redrawstatus')
  end,
})

