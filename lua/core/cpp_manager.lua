local M = {}

-- Помощник для работы с CMakeLists.txt
function M.update_cmake_lists(root, filename, action)
  local cmake_path = root .. "/CMakeLists.txt"
  if vim.fn.filereadable(cmake_path) == 0 then return end

  local lines = vim.fn.readfile(cmake_path)
  local new_lines = {}
  local in_sources_block = false
  local block_end_idx = -1
  local already_exists = false

  local hpp_entry = "    include/" .. filename .. ".hpp"
  local cpp_entry = "    src/" .. filename .. ".cpp"

  for i, line in ipairs(lines) do
    if line:match("^%s*set%s*%(%s*SOURCES") then
      in_sources_block = true
    end
    if in_sources_block then
      if line:match("include/" .. filename .. "%.hpp") or line:match("src/" .. filename .. "%.cpp") then
        already_exists = true
      end
      if line:match("%s*%)%s*$") then
        in_sources_block = false
        block_end_idx = i
        break
      end
    end
  end

  if action == "add" then
    if already_exists then return end
    if block_end_idx ~= -1 then
      table.insert(lines, block_end_idx, cpp_entry)
      table.insert(lines, block_end_idx, hpp_entry)
      vim.fn.writefile(lines, cmake_path)
    end
  elseif action == "remove" then
    for _, line in ipairs(lines) do
      if not (line:match("include/" .. filename .. "%.hpp") or line:match("src/" .. filename .. "%.cpp")) then
        table.insert(new_lines, line)
      end
    end
    vim.fn.writefile(new_lines, cmake_path)
  end
end

-- Логика создания
function M.handle_file_creation(filepath)
  if not filepath:match("%.hpp$") then return end

  local root = vim.fs.root(0, { ".git", "CMakeLists.txt" }) or vim.fn.getcwd()
  local filename = vim.fn.fnamemodify(filepath, ":t:r")
  
  if filepath:match(root .. "/include/") then return end

  local include_dir = root .. "/include"
  local src_dir = root .. "/src"
  local hpp_path = include_dir .. "/" .. filename .. ".hpp"
  local cpp_path = src_dir .. "/" .. filename .. ".cpp"

  if vim.fn.isdirectory(include_dir) == 0 then vim.fn.mkdir(include_dir, "p") end
  if vim.fn.isdirectory(src_dir) == 0 then vim.fn.mkdir(src_dir, "p") end

  local hpp_content = { "#pragma once", "" }
  local cpp_content = { '#include "../include/' .. filename .. '.hpp"', "" }

  if vim.fn.filereadable(cpp_path) == 0 then vim.fn.writefile(cpp_content, cpp_path) end
  if vim.fn.filereadable(hpp_path) == 0 then vim.fn.writefile(hpp_content, hpp_path) end

  M.update_cmake_lists(root, filename, "add")
  return hpp_path, filename
end

-- Логика удаления
function M.handle_file_deletion(filepath)
  if not (filepath:match("%.hpp$") or filepath:match("%.cpp$")) then return end

  local root = vim.fs.root(0, { ".git", "CMakeLists.txt" }) or vim.fn.getcwd()
  local filename = vim.fn.fnamemodify(filepath, ":t:r")
  local ext = vim.fn.fnamemodify(filepath, ":e")

  local pair_path = ""
  if ext == "hpp" then
    pair_path = root .. "/src/" .. filename .. ".cpp"
  elseif ext == "cpp" then
    pair_path = root .. "/include/" .. filename .. ".hpp"
  end

  if pair_path ~= "" and vim.fn.filereadable(pair_path) == 1 then
    vim.fn.delete(pair_path)
    local pair_buf = vim.fn.bufnr(pair_path)
    if pair_buf ~= -1 then vim.cmd("bdelete! " .. pair_buf) end
  end

  M.update_cmake_lists(root, filename, "remove")
end

-- Оставляем классические автокоманды для работы через :e
local cpp_project_group = vim.api.nvim_create_augroup("CppProjectManager", { clear = true })
vim.api.nvim_create_autocmd("BufNewFile", {
  group = cpp_project_group,
  pattern = "*.hpp",
  callback = function()
    local filepath = vim.fn.expand("<afile>:p")
    local correct_hpp = M.handle_file_creation(filepath)
    if correct_hpp then
      vim.cmd("bdelete!")
      vim.cmd("edit " .. vim.fn.fnameescape(correct_hpp))
    end
  end,
})


-- Функция для асинхронной сборки и запуска SFML проекта
function M.build_and_run()
  -- Автоматически сохраняем все файлы перед сборкой, чтобы не запускать старый код
  vim.cmd("silent! wa")

  local root = vim.fs.root(0, { "CMakeLists.txt" }) or vim.fn.getcwd()
  
  -- Имя вашего исполняемого файла из add_executable в CMakeLists.txt
  -- Скрипт попытается найти его сам, если не найдет — подставит "arcanoid_cpp"
  local binary_name = "arcanoid_cpp"
  local cmake_file = root .. "/CMakeLists.txt"
  if vim.fn.filereadable(cmake_file) == 1 then
    for _, line in ipairs(vim.fn.readfile(cmake_file)) do
      local match = line:match("add_executable%s*%((%w+)")
      if match then
        binary_name = match
        break
      end
    end
  end

  -- Путь к исполняемому файлу (обычно в папке build/ или в корне, зависит от настроек CMake)
  -- Скрипт проверяет оба варианта
  local run_cmd = "./" .. binary_name
  if vim.fn.isdirectory(root .. "/build") == 1 then
    run_cmd = "./build/" .. binary_name
  end

  -- Собираем команду: заходим в корень, собираем через cmake и запускаем
  local full_command = string.format("cd %s && cmake --build build && %s", vim.fn.fnameescape(root), run_cmd)

  -- Открываем горизонтальное окно терминала внизу экрана для вывода процесса сборки
  vim.cmd("botright split | terminal " .. full_command)
  
  -- Включаем режим терминала, чтобы он автоматически прокручивался вниз
  vim.cmd("startinsert")
  
  -- Добавляем автокоманду: когда процесс завершится (игра закроется), 
  -- окно терминала не закроется само, чтобы вы могли увидеть ошибки компиляции, если они будут.
  vim.bo.bufhidden = "wipe"
end

return M
