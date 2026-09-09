local function extract_method_to_end()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_line_num = vim.api.nvim_win_get_cursor(0)[1] -- Получаем текущую строку (число)
  local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  
  local current_line = all_lines[current_line_num]
  if not current_line or current_line:match("^%s*$") then
    vim.notify("Курсор должен быть на строке с методом", vim.log.levels.WARN)
    return
  end

  -- 1. Ищем имя класса, поднимаясь вверх от курсора
  local class_name = ""
  for i = current_line_num, 1, -1 do
    local line = all_lines[i]
    if line and (line:match("class%s+([%a_][%w_]*)") or line:match("struct%s+([%a_][%w_]*)")) then
      class_name = line:match("class%s+([%a_][%w_]*)") or line:match("struct%s+([%a_][%w_]*)")
      break
    end
  end

  if class_name == "" then
    vim.notify("Не удалось найти класс выше по тексту", vim.log.levels.ERROR)
    return
  end

  -- 2. Берем только текущую строку и очищаем её от левых отступов класса
  local base_indent = current_line:match("^%s*") or ""
  local cleaned_line = current_line:sub(#base_indent + 1)

  -- Очищаем строку от возможных остатков фигурных скобок или точек с запятой
  cleaned_line = cleaned_line:gsub("%s*{.*$", ""):gsub(";%s*$", "")

  -- 3. Трансформируем сигнатуру: добавляем ИмяКласса:: перед именем функции
  local transformed_text, count = cleaned_line:gsub("([%a_][%w_]*)%s*(%()", class_name .. "::%1%2", 1)

  if count == 0 then
    vim.notify("Не удалось разобрать сигнатуру функции. Проверьте строку.", vim.log.levels.WARN)
    return
  end

  -- Формируем красивое пустое тело функции для конца файла
  transformed_text = transformed_text .. " {\n\n}"

  -- 4. Заменяем исходную строку внутри класса на чистый прототип (добавляем ';')
  local proto_line = base_indent .. cleaned_line .. ";"
  vim.api.nvim_buf_set_lines(bufnr, current_line_num - 1, current_line_num, false, { proto_line })

  -- 5. Дописываем трансформированный метод в самый конец файла C++ без отступов
  local last_line = vim.api.nvim_buf_line_count(bufnr)
  local final_lines = { "", "" } -- Две пустые строки для разделения методов в C++
  for line in string.gmatch(transformed_text, "[^\r\n]+") do
    table.insert(final_lines, line)
  end

  vim.api.nvim_buf_set_lines(bufnr, last_line, last_line, false, final_lines)
  vim.notify("Скелет метода " .. class_name .. ":: успешно вынесен в конец файла!", vim.log.levels.INFO)
end

-- Привязка на Пробел + m
vim.keymap.set('n', '<leader>m', extract_method_to_end, { buffer = true, desc = 'C++: Extract method skeleton to end' })
