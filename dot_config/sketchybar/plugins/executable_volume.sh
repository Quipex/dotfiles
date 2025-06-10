#!/usr/bin/env zsh

function mylog() {
  # Проверяем, существует ли директория ~/tmp
  # Если нет, создаем ее
  mkdir -p ~/tmp

  # Записываем сообщение в файл ~/tmp/logs
  # -e позволяет интерпретировать escape-последовательности, хотя здесь это не критично
  # >> добавляет вывод в конец файла, не перезаписывая его
  echo "[volume] $@" >> ~/tmp/logs
}

mylog "INFO=$INFO"


case ${INFO} in
0)
    ICON=""
    ICON_PADDING_RIGHT=21
    ;;
[0-9])
    ICON=""
    ICON_PADDING_RIGHT=12
    ;;
*)
    ICON=""
    ICON_PADDING_RIGHT=6
    ;;
esac

sketchybar --set $NAME icon=$ICON icon.padding_right=$ICON_PADDING_RIGHT label="$INFO%"