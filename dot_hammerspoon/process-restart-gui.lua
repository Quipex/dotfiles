-- GUI-утилита выбора процессов для перезапуска (Hammerspoon).
-- Окно на webview с чекбоксами, "Выбрать всё", Enter для запуска, Esc для отмены.
-- Логи: ~/.hammerspoon/logs/process-restart.log
-- ===== Настройки путей и окружения =====
local SH = "/bin/sh"
local PKILL = "/usr/bin/pkill"
local OPEN = "/usr/bin/open"
local SKETCHYBAR = "/opt/homebrew/bin/sketchybar"

local HOME = os.getenv("HOME")
local logDir = HOME .. "/.hammerspoon/logs"
hs.fs.mkdir(logDir)
local logFile = logDir .. "/process-restart.log"

local PATH = table.concat(
    {"/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"}, ":")

local function log(line)
    local cmd = string.format([[printf "%%s\n" "%s" >> "%s"]], line, logFile)
    hs.task.new(SH, nil, {"-c", cmd}):start()
end

-- ===== Действия (что перезапускаем) =====
local function restartSketchybar()
    log("=== Restart Sketchybar ===")
    hs.task.new(PKILL, nil, {"-x", "sketchybar"}):start()
    hs.timer.usleep(300000) -- 0.3 c
    local cmd = string.format('PATH=%s; export PATH; nohup "%s" >>"%s" 2>&1 &', PATH, SKETCHYBAR, logFile)
    hs.task.new(SH, nil, {"-c", cmd}):start()
end

local function reloadHammerspoon()
    log("=== Reload Hammerspoon config ===")
    hs.reload()
end

local function restartAeroSpace()
    log("=== Restart AeroSpace ===")
    hs.task.new(PKILL, nil, {"-x", "AeroSpace"}):start()
    hs.timer.usleep(300000)
    hs.task.new(OPEN, nil, {"-a", "AeroSpace"}):start()
end

local actions = {{
    id = "reload_hs",
    title = "Перезагрузить конфиг Hammerspoon",
    run = reloadHammerspoon
}, {
    id = "restart_sketchybar",
    title = "Перезапустить Sketchybar",
    run = restartSketchybar
}, {
    id = "restart_aerospace",
    title = "Перезапустить AeroSpace",
    run = restartAeroSpace
}}

local actionsById = {}
for _, a in ipairs(actions) do
    actionsById[a.id] = a
end

-- ===== HTML интерфейс =====
local function buildHTML()
    local items = {}
    table.insert(items, [[
    <label class="all"><input type="checkbox" id="selectAll"> Выбрать всё</label>
    <hr>
  ]])
    for _, a in ipairs(actions) do
        table.insert(items, string.format([[
      <label><input type="checkbox" class="item" value="%s"> %s</label>
    ]], a.id, a.title))
    end
    local body = table.concat(items, "\n")

    local html = [[
  <!doctype html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>Перезапуск процессов</title>
    <style>
      body { font-family: -apple-system, Helvetica, Arial, sans-serif; margin: 16px; }
      h1 { margin: 0 0 12px 0; font-size: 16px; }
      .list { max-height: 260px; overflow-y: auto; padding: 8px; border: 1px solid #ddd; border-radius: 8px; }
      label { display: block; margin: 8px 0; }
      label.all { font-weight: 600; }
      .btns { margin-top: 12px; display: flex; gap: 8px; }
      button { padding: 8px 12px; border-radius: 8px; border: 1px solid #ccc; background: #f6f6f6; cursor: pointer; }
      button.primary { background: #eaeaea; }
      small { color: #666; }
    </style>
  </head>
  <body>
    <h1>Выбери процессы для перезапуска</h1>
    <div class="list">]] .. body .. [[</div>
    <div class="btns">
      <button id="run" class="primary">Перезапустить выбранное (Enter)</button>
      <button id="cancel">Отмена (Esc)</button>
    </div>
    <p><small>Подсказки: Space — ставить/снимать чекбокс; Esc — закрыть окно.</small></p>

    <script>
      const selectAll = document.getElementById('selectAll');
      const items = Array.from(document.querySelectorAll('.item'));
      function syncSelectAll() {
        const allChecked = items.every(i => i.checked);
        const anyChecked = items.some(i => i.checked);
        selectAll.indeterminate = anyChecked && !allChecked;
        selectAll.checked = allChecked;
      }
      selectAll.addEventListener('change', () => {
        items.forEach(i => i.checked = selectAll.checked);
        syncSelectAll();
      });
      items.forEach(i => i.addEventListener('change', syncSelectAll));
      syncSelectAll();

      function runSelected() {
        const ids = items.filter(i => i.checked).map(i => i.value);
        const query = encodeURIComponent(ids.join(','));
        window.location.href = 'hammerspoon://process-restart?ids=' + query;
      }
      function cancel() {
        window.location.href = 'hammerspoon://process-restart-cancel';
      }

      document.getElementById('run').addEventListener('click', runSelected);
      document.getElementById('cancel').addEventListener('click', cancel);

      document.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') { e.preventDefault(); runSelected(); }
        if (e.key === 'Escape') { e.preventDefault(); cancel(); }
      });
    </script>
  </body>
  </html>
  ]]
    return html
end

-- ===== WebView окно и обработчики =====
local w -- webview окно (глобально в модуле)

local function closeWindow()
    if w and w:hswindow() then
        w:delete()
    end
    w = nil
end

-- Обработчик hammerspoon://process-restart
hs.urlevent.bind("process-restart", function(_, params, _)
    local ids = {}
    if params and params["ids"] then
        for id in tostring(params["ids"]):gmatch("([^,]+)") do
            table.insert(ids, id)
        end
    end
    closeWindow()

    if #ids == 0 then
        hs.alert.show("Ничего не выбрано")
        return
    end

    local executed = {}
    for _, id in ipairs(ids) do
        local act = actionsById[id]
        if act and type(act.run) == "function" then
            log("Run: " .. act.title)
            act.run()
            table.insert(executed, "• " .. act.title)
        end
    end
    if #executed > 0 then
        hs.alert.show("Выполнено:\n" .. table.concat(executed, "\n"))
    end
end)

hs.urlevent.bind("process-restart-cancel", function()
    closeWindow();
    hs.alert.show("Отменено")
end)

local function show()
    if w then
        closeWindow()
    end
    local screenFrame = hs.screen.mainScreen():frame()
    local width, height = 520, 420
    local x = screenFrame.x + (screenFrame.w - width) / 2
    local y = screenFrame.y + (screenFrame.h - height) / 3

    w = hs.webview.new({
        x = x,
        y = y,
        w = width,
        h = height
    }):windowTitle("Перезапуск процессов"):allowTextEntry(true):closeOnEscape(true)
        :bringToFront(true):html(buildHTML())
    w:show()
end

return {
    show = show
}
