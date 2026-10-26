return {
  "neovim/nvim-lspconfig",
  config = function()
    -- Функция для автоматического поиска venv на диске в корне проекта
    local function get_python_path()
      -- Если venv уже активирован в терминале, берем его сразу
      if vim.env.VIRTUAL_ENV then
        return vim.env.VIRTUAL_ENV .. "/bin/python"
      end

      -- Иначе ищем локальные папки окружения в текущей рабочей директории
      local cwd = vim.fn.getcwd()
      local venv_variants = { "venv", ".venv" }
      for _, venv in ipairs(venv_variants) do
        local path = cwd .. "/" .. venv .. "/bin/python"
        if vim.fn.executable(path) == 1 then
          return path
        end
      end

      -- На крайний случай возвращаем системный python
      return "python3"
    end

    -- Настройка автокоманд при подключении любого LSP-сервера
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        
        -- Динамическая конфигурация для Pyright
        if client and client.name == "pyright" then
          client.config.settings = client.config.settings or {}
          client.config.settings.python = client.config.settings.python or {}
          
          -- Назначаем правильный путь к интерпретатору
          client.config.settings.python.pythonPath = get_python_path()
          
          -- Настройки анализатора, чтобы Django не подсвечивался как ошибка
          client.config.settings.python.analysis = {
            typeCheckingMode = "basic",          -- Базовая проверка типов
            reportAttributeAccessIssue = "none", -- Игнорировать ложные ошибки на Django .objects
          }
          
          -- [ИСПРАВЛЕНО] Используем актуальный способ обновления настроек вместо client.notify
          if client.settings then
            client.settings = client.config.settings
          end
        end

        -- [ГОРЯЧИЕ КЛАВИШИ] Для перемещения по коду и исправления ошибок
        local opts = { buffer = args.buf, silent = true }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)       -- Перейти к определению
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)             -- Показать документацию/типы под курсором
        vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- Показать текст ошибки строки в окошке
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)     -- Прыгнуть к предыдущей ошибке
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)     -- Прыгнуть к следующей ошибке
      end,
    })

    -- [ВКЛЮЧЕНИЕ СЕРВЕРОВ] Через нативный API Neovim
    if vim.lsp.enable then
      vim.lsp.enable('pyright')
      vim.lsp.enable('vtsls') 
      vim.lsp.enable('html')
      vim.lsp.enable('cssls')
      vim.lsp.enable('clangd')
    end
  end
}
