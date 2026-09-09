return {
  "neovim/nvim-lspconfig",
  config = function()
    -- Настройка автокоманд при подключении любого LSP-сервера
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        
        -- [СОХРАНЕНО] Ваша логика для Python venv
        if client and client.name == "pyright" and vim.env.VIRTUAL_ENV then
          client.config.settings.python = client.config.settings.python or {}
          client.config.settings.python.pythonPath = vim.env.VIRTUAL_ENV .. "/bin/python"
          client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
        end

        -- [ГОРЯЧИЕ КЛАВИШИ] Для перемещения по коду и исправления ошибок
        local opts = { buffer = args.buf, silent = true }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)       -- Перейти к определению (где создана функция/переменная)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)             -- Показать документацию/типы под курсором
        vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- Показать текст ошибки строки в окошке
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)     -- Прыгнуть к предыдущей ошибке
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)     -- Прыгнуть к следующей ошибке
      end,
    })

    -- [НОВЫЙ СИНТАКСИС] Включение серверов через нативный API Neovim (без require('lspconfig'))
    if vim.lsp.enable then
      vim.lsp.enable('pyright')
      vim.lsp.enable('vtsls') 
      vim.lsp.enable('html')
      vim.lsp.enable('cssls')
      vim.lsp.enable('clangd')
    end
  end
}
