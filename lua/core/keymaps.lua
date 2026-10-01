-- Функция запуска кода

local function run_current_file()
  local file_ext = vim.bo.filetype
  local file_path = vim.fn.expand("%:p")
  vim.cmd("w")

  local cmd = ""
  if file_ext == "python" then
    local venv_python = vim.fn.getcwd() .. "/venv/bin/python"
    local dot_venv_python = vim.fn.getcwd() .. "/.venv/bin/python"
    local python_bin = "python3"

    if vim.fn.executable(venv_python) == 1 then
      python_bin = venv_python
    elseif vim.fn.executable(dot_venv_python) == 1 then
      python_bin = dot_venv_python
    end

    cmd = "env DISPLAY=" .. (os.getenv("DISPLAY") or ":0") .. " WAYLAND_DISPLAY=" .. (os.getenv("WAYLAND_DISPLAY") or "") .. " " .. python_bin .. " " .. file_path
  
  elseif file_ext == "cpp" then
    -- Проверяем, есть ли CMakeLists.txt в корневой папке проекта
    if vim.fn.filereadable("CMakeLists.txt") == 1 then
      -- Получаем имя текущей директории для запуска бинарника
      -- Например, если проект в папке 'arcanoid_cpp', имя будет 'arcanoid_cpp'
      local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
      
      -- Команда: генерируем билд в папку build, собираем и запускаем бинарник
      cmd = "cmake -B build && cmake --build build && ./build/" .. project_name
      
      -- ПРИМЕЧАНИЕ: Если у вас в CMakeLists.txt исполняемый файл жестко
      -- назван по-другому (например, app_out), то закомментируйте строку выше
      -- и раскомментируйте строку ниже:
      -- cmd = "cmake -B build && cmake --build build && ./build/app_out"
    else
      -- Если CMake нет, запускаем как одиночный файл (ваш старый вариант)
      cmd = "g++ " .. file_path .. " -o app_out && ./app_out"
    end
    
  else
    print("Автозапуск для этого типа файлов не настроен")
    return
  end

  -- 1. Создаем абсолютно новый пустой буфер для терминала
  local term_buf = vim.api.nvim_create_buf(false, true)
  
  -- 2. Открываем сплит снизу и сразу делаем его активным
  vim.cmd("belowright 12split")
  local term_win = vim.api.nvim_get_current_win()
  
  -- 3. Привязываем наш созданный буфер к этому нижнему окну
  vim.api.nvim_win_set_buf(term_win, term_buf)
  
  -- 4. Запускаем программу внутри этого буфера
  vim.fn.termopen(cmd)
  
  -- 5. Обработка закрытия по нажатию Enter
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = term_buf,
    once = true,
    callback = function()
      print("Программа завершена. Нажмите Enter для закрытия окна...")
      
      vim.keymap.set("n", "<CR>", function()
        -- Закрываем окно терминала (сплит схлопнется)
        if vim.api.nvim_win_is_valid(term_win) then
          vim.api.nvim_win_close(term_win, true)
        end
        
        -- Удаляем сам терминальный буфер из памяти
        if vim.api.nvim_buf_is_valid(term_buf) then
          vim.api.nvim_buf_delete(term_buf, { force = true })
        end
        
        -- Полностью обновляем экран, убирая любые баги отрисовки
        vim.cmd("redraw!")
      end, { buffer = term_buf, silent = true })
    end,
  })
end
-- Привязка клавиш

vim.keymap.set("n", "<leader>r", run_current_file, { silent = true })
vim.keymap.set("n", "<leader>g", ":LazyGit<CR>", { silent = true })

-- Открыть/закрыть дерево файлов на Space + e (если лидер-клавиша установлена на Space)
vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { silent = true })

vim.keymap.set('n', '<M-h>', ':BufferLineCyclePrev<CR>', { silent = true })
vim.keymap.set('n', '<M-l>', ':BufferLineCycleNext<CR>', { silent = true })

-- 2. Аккуратное закрытие текущей вкладки на Space + x (без потери фокуса)
vim.keymap.set('n', '<leader>x', ':Bdelete<CR>', { silent = true })

-- 3. Быстрое открытие/закрытие бокового дерева файлов на Space + e
vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { silent = true })
-- Шорткат <Leader>gr сбросит текущий файл к последнему коммиту и обновит буфер
vim.keymap.set('n', '<Leader>gr', ':!git checkout HEAD -- %<CR>:e!<CR>', { silent = true, desc = "Откатить файл к коммиту" })

-- Запуск сборки и выполнения C++ проекта по Leader + Shift + R
vim.keymap.set("n", "<leader>R", function()
  require("core.cpp_manager").build_and_run()
end, { desc = "CMake: Собрать и запустить проект" })
