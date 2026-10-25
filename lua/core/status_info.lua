local M = {}

-- Путь к файлу сохранения данных таймеров
local save_path = vim.fn.stdpath("data") .. "/folder_timers.json"

-- Вспомогательные функции для чтения и записи JSON
local function load_timers()
  local file = io.open(save_path, "r")
  if not file then return {} end
  local content = file:read("*a")
  file:close()
  local ok, data = pcall(vim.json.decode, content)
  return ok and data or {}
end

local function save_timers(data)
  local file = io.open(save_path, "w")
  if file then
    file:write(vim.json.encode(data))
    file:close()
  end
end

-- Инициализируем данные текущей сессии
local global_start_time = os.time()
local current_folder_path = vim.fn.getcwd()
local current_folder_name = vim.fn.fnamemodify(current_folder_path, ":t")

-- Загружаем сохраненную историю времени для текущей папки
local saved_timers = load_timers()
local initial_folder_seconds = saved_timers[current_folder_path] or 0

-- Переменные для асинхронных данных (раскладка и строки проекта)
_G.current_system_layout = "en"
_G.project_total_lines = "считаю..."

-- 2. Асинхронное получение раскладки (Ubuntu Wayland)
local function update_layout_async()
  local stdout = vim.loop.new_pipe(false)
  local handle
  handle = vim.loop.spawn("gdbus", {
    args = { "call", "--session", "--dest", "org.gnome.Shell", "--object-path", "/org/gnome/Shell", "--method", "org.gnome.Shell.Extensions.Keyboard.GetLayouts" },
    stdio = { nil, stdout, nil }
  }, function()
    if handle then handle:close() end
  end)

  if handle then
    vim.loop.read_start(stdout, function(err, data)
      if data then
        local clean_data = data:gsub("%s+", ""):lower()
        if string.find(clean_data, "'ru'") or string.find(clean_data, '"ru"') then
          _G.current_system_layout = "ru"
        else
          _G.current_system_layout = "en"
        end
      end
      stdout:close()
    end)
  end
end

-- Вспомогательная проверка раскладки (gsettings fallback)
local function fallback_layout_check()
  local handle = io.popen("gsettings get org.gnome.desktop.input-sources mru-sources 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result then
      local first_layout = result:match("%('xkb',%s*'([a-z]+)'%)")
      if first_layout == "ru" then _G.current_system_layout = "ru" else _G.current_system_layout = "en" end
    end
  end
end

-- Получение суммарного количества диагностических ошибок в текущем буфере
local function get_diagnostics()
  if not vim.diagnostic or not vim.diagnostic.get then return "" end
  local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  
  local result = ""
  if errors > 0 then result = result .. string.format(" 🔴 E:%d", errors) end
  if warnings > 0 then result = result .. string.format(" 🟡 W:%d", warnings) end
  return result
end

-- Расчет времени общей сессии Neovim
local function get_session_time()
  local diff = os.difftime(os.time(), global_start_time)
  local hours = math.floor(diff / 3600)
  local minutes = math.floor((diff % 3600) / 60)
  local seconds = diff % 60
  return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Расчет и автосохранение суммирующегося времени проекта (с поддержкой сотен часов %03d)
local function get_folder_time()
  local current_session_diff = os.difftime(os.time(), global_start_time)
  local total_folder_seconds = initial_folder_seconds + current_session_diff

  -- Раз в 10 секунд сохраняем прогресс на диск
  if current_session_diff % 10 == 0 then
    local current_data = load_timers()
    current_data[current_folder_path] = total_folder_seconds
    save_timers(current_data)
  end

  -- Считаем часы (формат %03d резервирует 3 знака под сотни часов: 001, 150, 999)
  local hours = math.floor(total_folder_seconds / 3600)
  local minutes = math.floor((total_folder_seconds % 3600) / 60)
  local seconds = total_folder_seconds % 60
  return string.format("%s: %03d:%02d:%02d", current_folder_name, hours, minutes, seconds)
end

-- Главная функция сборки строки состояния
function M.full_statusline()
  update_layout_async()
  fallback_layout_check()
  
  local layout = _G.current_system_layout
  local session = get_session_time()
  local folder_time = get_folder_time()
  local diagnostics = get_diagnostics()
  local datetime = os.date("%H:%M:%S")
  
  -- Добавили вывод [Строк в проекте: ...] на панель
  return string.format(
    " %%f%s %%= [Язык: %s] | [Общее: %s] | [%s] | [%s] ", 
    diagnostics, layout, session, folder_time, datetime
  )
end

-- Сохраняем точное время при выходе из Neovim
vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
  pattern = "*",
  callback = function()
    local current_data = load_timers()
    local current_session_diff = os.difftime(os.time(), global_start_time)
    current_data[current_folder_path] = initial_folder_seconds + current_session_diff
    save_timers(current_data)
  end,
})

return M
