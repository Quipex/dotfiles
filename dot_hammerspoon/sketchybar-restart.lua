-- Полные пути к бинарям
local SH = "/bin/sh"
local PKILL = "/usr/bin/pkill"
local SKETCHYBAR = "/opt/homebrew/bin/sketchybar"

-- Путь к конфигу sketchybar
local HOME = os.getenv("HOME")
local CONFIG = HOME .. "/.config/sketchybar/sketchybarrc"

-- Куда писать логи
local logDir = HOME .. "/.hammerspoon/logs"
hs.fs.mkdir(logDir)
local logFile = logDir .. "/sketchybar.log"

-- Явный PATH для sketchybar и всех его плагинов
local PATH = table.concat(
    {"/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"}, ":")

local function file_exists(path)
    local attr = hs.fs.attributes(path)
    return attr ~= nil and attr.mode == "file"
end

local function restartSketchybar()
    -- 0) Заголовок логов
    local header = string.format(
        'echo "\\n=== Restart at $(date) ===" >>"%s"; echo "PATH=%s" >>"%s"; "%s" -v >>"%s" 2>&1', logFile, PATH,
        logFile, SKETCHYBAR, logFile)
    hs.task.new(SH, nil, {"-c", header}):start()

    -- 1) Погасим предыдущий процесс
    hs.task.new(PKILL, nil, {"-x", "sketchybar"}):start()
    hs.timer.usleep(300000) -- 0.3 c

    -- 2) Проверим наличие конфига и залогируем
    if not file_exists(CONFIG) then
        local msg = string.format('echo "WARN: config not found: %s" >>"%s"', CONFIG, logFile)
        hs.task.new(SH, nil, {"-c", msg}):start()
    else
        -- Быстрая проверка синтаксиса bash-конфига
        local check = string.format('bash -n "%s" 2>>"%s" || echo "ERROR: syntax check failed for %s" >>"%s"', CONFIG,
            logFile, CONFIG, logFile)
        hs.task.new(SH, nil, {"-c", check}):start()
    end

    -- 3) Стартуем sketchybar в фоне, явно указывая конфиг и PATH, отвязываем stdout/stderr
    local cmd = string.format('PATH=%s; export PATH; ' .. 'if [ -f "%s" ]; then ' ..
                                  '  nohup "%s" --config "%s" >>"%s" 2>&1 & ' .. 'else ' ..
                                  '  nohup "%s" >>"%s" 2>&1 & ' .. 'fi', PATH, CONFIG, SKETCHYBAR, CONFIG, logFile,
        SKETCHYBAR, logFile)

    hs.task.new(SH, function(code, _, _)
        if code == 0 then
            hs.alert.show("sketchybar: перезапуск")
        else
            hs.alert.show("sketchybar: ошибка запуска, ~/.hammerspoon/logs/sketchybar.log")
        end
    end, {"-c", cmd}):start()
end

-- Горячая клавиша Shift+Alt+R
hs.hotkey.bind({"alt", "shift"}, "R", restartSketchybar)

-- Экспортируем функцию (на случай, если захочешь вызвать из init.lua)
return {
    restart = restartSketchybar
}
