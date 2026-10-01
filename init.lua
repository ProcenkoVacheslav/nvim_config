-- Глобальный Leader (Пробел) ДОЛЖЕН быть объявлен первым
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 1. Подключаем настройки интерфейса, автокоманды и хаки
require("core.options")
require("core.autocmds")
require("core.cpp_manager")

-- 2. Путь к менеджеру плагинов lazy.nvim и установка
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 3. Настраиваем lazy.nvim на автоматическое чтение папки lua/plugins/
require("lazy").setup("plugins", {
    checker = { enabled = false },
    lockfile = "/dev/null" -- Твоя настройка против генерации лишних файлов
})

-- 4. Подключаем глобальные горячие клавиши (после инициализации плагинов)
require("core.keymaps")
