-- Запрещаем Treesitter запускаться на файлах конфигурации Lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    pcall(function() vim.treesitter.stop() end)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "html", "xml", "jinja", "javascriptreact", "typescriptreact" },
  callback = function()
    vim.keymap.set("i", ">", function()
      local line = vim.api.nvim_get_current_line()
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local tag = line:sub(1, col):match("<([%w%-]+)[^>]*$")
      
      if tag and not line:sub(1, col):match("</" .. tag .. ">$") and not line:sub(1, col):match("/$") then
        local close_tag = "</" .. tag .. ">"
        vim.api.nvim_feedkeys(">" .. close_tag, "n", false)
        
        vim.schedule(function()
          vim.api.nvim_win_get_cursor(0)
          vim.api.nvim_win_set_cursor(0, { row, col + 1 })
        end)
        return ""
      else
        return ">"
      end
    end, { expr = true, buffer = true })
  end,
})

-- Автоматическое форматирование кода при сохранении файла
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.py", "*.js", "*.css" },
  callback = function()
    local file_ext = vim.bo.filetype
    if file_ext == "python" then
      vim.cmd("%!black -q -")
    elseif file_ext == "javascript" or file_ext == "html" or file_ext == "css" then
      vim.cmd("%!prettier --stdin-filepath " .. vim.fn.expand("%"))
    end
  end,
})

local function auto_activate_venv()
  local venv_names = { "venv", ".venv", "env" }
  local cwd = vim.fn.getcwd()

  for _, name in ipairs(venv_names) do
    local venv_path = cwd .. "/" .. name
    if vim.fn.executable(venv_path .. "/bin/python") == 1 then
      vim.env.VIRTUAL_ENV = venv_path
      vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH
      vim.notify("Активировано окружение: " .. name, vim.log.levels.INFO)
      break
    end
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = auto_activate_venv,
})

local my_line_group = vim.api.nvim_create_augroup("MaxLineLengthVisual", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = my_line_group,
  pattern = { "python", "javascript", "cpp" },
  callback = function()
      vim.opt_local.colorcolumn = "80"
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*";
    callback = function()
        class_color = { fg = "#8ABEB7", bold=true }

        vim.api.nvim_set_hl(0, "@lsp.type.class.cpp", class_color)

        vim.api.nvim_set_hl(0, "@lsp-typemod.class.declaration.cpp", class_color)
        vim.api.nvim_set_hl(0, "@lsp-typemod.class.globalScope.cpp", class_color)
        vim.api.nvim_set_hl(0, "@lsp.type.class.declaration.globalScope.cpp", class_color)
    end;
})
