-- ~/.hammerspoon/window-manipulation.lua

-- 1. Создаем таблицу, которая будет нашим "модулем" или "toolbox"
local module = {}

-- 2. Определяем нашу функцию и прикрепляем ее к таблице модуля
function module.moveWindowToCursor()
  local mousePos = hs.mouse.getAbsolutePosition()
  local app = hs.application.frontmostApplication()
  local win = app and app:mainWindow()

  if not win then
    win = hs.window.focusedWindow()
  end

  if not win then
    hs.notify.show("Hammerspoon", "Окно не найдено", "Не удалось определить активное окно.")
    return
  end

  if win:isMinimized() then
    win:unminimize()
  end

  win:focus()
  win:setTopLeft(mousePos)
  hs.alert.show("Окно перемещено")
end

-- Вы можете добавить сюда и другие функции по управлению окнами
function module.centerFocusedWindow()
    local win = hs.window.focusedWindow()
    if win then
        win:centerOnScreen()
    end
end


-- 3. Возвращаем нашу таблицу, чтобы другие файлы могли ее использовать
return module
