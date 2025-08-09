-- GUI-утилита выбора процессов для перезапуска (Hammerspoon).
-- Окно сразу в фокусе; управление: ↑/↓ (навигация), Space (выбор), Enter (подтвердить),
-- цифры 1..9 и 0 (=10-й пункт) — переключают соответствующий пункт.
-- Логи: ~/.hammerspoon/logs/process-restart.log
-- ===== Пути и окружение =====
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

-- ===== Действия =====
local function restartSketchybar()
    log("=== Restart Sketchybar ===")
    hs.task.new(PKILL, nil, {"-x", "sketchybar"}):start()
    hs.timer.usleep(300000)
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
    for i, a in ipairs(actions) do
        -- Пронумеруем пункты в тексте: [1], [2], ...
        table.insert(items, string.format([[
      <label class="row"><input type="checkbox" class="item" value="%s"> <span class="num">[%d]</span> %s</label>
    ]], a.id, i, a.title))
    end
    local body = table.concat(items, "\n")

    local html = [[
  <!doctype html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>Перезапуск процессов</title>
    <style>
      :root { color-scheme: light dark; }
      body { font-family: -apple-system, Helvetica, Arial, sans-serif; margin: 16px; }
      h1 { margin: 0 0 12px 0; font-size: 16px; }
      .list { max-height: 260px; overflow-y: auto; padding: 8px; border: 1px solid #ddd; border-radius: 8px; }
      label { display: block; margin: 8px 0; }
      label.all { font-weight: 600; }
      .row { padding: 4px 6px; border-radius: 6px; }
      .row.focused { outline: 2px solid rgba(0,122,255,.6); background: rgba(0,122,255,.07); }
      .num { color: #888; width: 32px; display: inline-block; }
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
    <p><small>Управление: ↑/↓ — навигация, Space — выбрать/снять, 1..9/0 — быстрый выбор, Enter — подтвердить, Esc — отмена.</small></p>

    <script>
      // Сбор элементов
      const selectAll = document.getElementById('selectAll');
      const rows  = Array.from(document.querySelectorAll('label.row'));
      const items = Array.from(document.querySelectorAll('.item')); // checkbox'ы внутри rows
      let idx = 0;  // индекс "фокуса" по списку items/rows

      function focusIndex(i) {
        if (rows[idx]) rows[idx].classList.remove('focused');
        idx = Math.max(0, Math.min(i, items.length - 1));
        rows[idx].classList.add('focused');
        items[idx].focus({preventScroll:true});
        rows[idx].scrollIntoView({ block: 'nearest' });
      }

      function syncSelectAll() {
        const allChecked = items.every(i => i.checked);
        const anyChecked = items.some(i => i.checked);
        selectAll.indeterminate = anyChecked && !allChecked;
        selectAll.checked = allChecked;
      }

      // Первичная инициализация
      selectAll.addEventListener('change', () => {
        items.forEach(i => i.checked = selectAll.checked);
        syncSelectAll();
      });
      items.forEach(i => i.addEventListener('change', syncSelectAll));
      syncSelectAll();

      // Сразу ставим фокус в список
      window.addEventListener('load', () => { focusIndex(0); });

      // Действия
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

      // Управление с клавиатуры
      document.addEventListener('keydown', (e) => {
        // Enter — подтвердить
        if (e.key === 'Enter') { e.preventDefault(); runSelected(); return; }
        // Esc — отмена
        if (e.key === 'Escape') { e.preventDefault(); cancel(); return; }
        // Навигация
        if (e.key === 'ArrowDown') { e.preventDefault(); focusIndex(idx + 1); return; }
        if (e.key === 'ArrowUp')   { e.preventDefault(); focusIndex(idx - 1); return; }
        // Пробел — переключить текущий пункт
        if (e.key === ' ') {
          e.preventDefault();
          if (items[idx]) {
            items[idx].checked = !items[idx].checked;
            syncSelectAll();
          }
          return;
        }
        // Цифры 1..9 — переключить соответствующий пункт; 0 — 10-й
        if (/^[0-9]$/.test(e.key)) {
          e.preventDefault();
          let n = (e.key === '0') ? 10 : parseInt(e.key, 10);
          let j = n - 1; // в массиве с 0
          if (j >= 0 && j < items.length) {
            items[j].checked = !items[j].checked;
            focusIndex(j);
            syncSelectAll();
          }
          return;
        }
      });
    </script>
  </body>
  </html>
  ]]
    return html
end

-- ===== WebView окно и обработчики =====
local w -- webview окно

local function closeWindow()
    if w and w:hswindow() then
        w:delete()
    end
    w = nil
end

-- Принятие выбора
hs.urlevent.bind("process-restart", function(_, params, _)
    local ids = {}
    if params and params["ids"] then
        for id in tostring(params["ids"]):gmatch("([^,]+)") do
            table.insert(ids, id)
        end
    end
    closeWindow()

    if #ids == 0 then
        hs.alert.show("Ничего не выбрано");
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
    -- центрируем на основном экране
    local screenFrame = hs.screen.mainScreen():frame()
    local width, height = 520, 420
    local x = screenFrame.x + (screenFrame.w - width) / 2
    local y = screenFrame.y + (screenFrame.h - height) / 3

    -- создаём webview
    w = hs.webview.new({
        x = x,
        y = y,
        w = width,
        h = height
    }):windowTitle("Перезапуск процессов"):allowTextEntry(true):closeOnEscape(true)
        :bringToFront(true):html(buildHTML())

    -- показываем и форсируем фокус окна
    w:show()
    local hw = w:hswindow()
    if hw then
        hw:focus()
        -- На некоторых версиях полезно поднять уровень, чтобы точно получить фокус:
        -- hw:setLevel(hs.drawing.windowLevels.modalPanel)
    end

    -- Доп. страховка: через микрозадержку повторно сфокусировать окно
    hs.timer.doAfter(0.05, function()
        if w and w:hswindow() then
            w:hswindow():focus()
        end
    end)
end

return {
    show = show
}
