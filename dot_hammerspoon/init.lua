-- ~/.hammerspoon/init.lua

-- Включаем возможность общаться с Hammerspoon из командной строки
require('hs.ipc')

-- Подключаем GUI-утилиту
local restartGui = require("process-restart-gui")

-- Горячая клавиша: Alt+Shift+E — открыть окно выбора, Enter — выполнить
hs.hotkey.bind({"alt","shift"}, "E", function()
  restartGui.show()
end)


-- 1. Импортируем наш модуль.
-- require() ищет файл 'window-manipulation.lua' в директории ~/.hammerspoon/
-- Переменная 'winManips' теперь содержит таблицу, которую мы вернули из того файла.
local winManips = require('window-manipulation')

-- 2. Определяем хоткеи, вызывая функции из нашего импортированного модуля
hs.hotkey.bind({"alt"}, "g", winManips.moveWindowToCursor)

-- Хоткей для перезагрузки конфига
hs.hotkey.bind({"alt"}, "r", function()
  hs.reload()
  hs.alert.show("Hammerspoon Reloaded")
end)

-- Уведомление о том, что конфигурация загружена
hs.notify.show("Hammerspoon", "Конфигурация загружена", "Модули подключены.")
