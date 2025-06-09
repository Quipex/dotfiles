#!/bin/bash

# Скрипт с прогрессом одной строкой (обрезка по ширине терминала) и чистым XML.

# --- Определяем ширину терминала (для stderr) ---
if [ -t 2 ]; then
  TERM_WIDTH=$(tput cols)
else
  TERM_WIDTH=80
fi

# --- Функция вывода прогресса ---
print_progress() {
  local counter="$1" total="$2" path="$3"
  local prefix="[$counter/$total] Processing: "
  local line="${prefix}${path}"
  if [ ${#line} -gt "$TERM_WIDTH" ]; then
    line="${line:0:TERM_WIDTH}"
  fi
  printf "\033[2K\r%s" "$line" >&2
}

# --- Вывод XML для файла ---
output_file_xml() {
  local file_to_process="$1"
  echo "  <file>"
  echo "    <file_path>"
  echo "      $file_to_process"
  echo "    </file_path>"
  echo "    <file_content>"
  cat "$file_to_process"
  echo
  echo "    </file_content>"
  echo "  </file>"
}

# --- Проверка расширения и обработка ---
check_and_process_file() {
  local current_file_path="$1"
  local extensions_filter_csv="$2"

  local filename_only="${current_file_path##*/}"
  local file_extension=""
  if [[ "$filename_only" == *.* && "$filename_only" != "." && "$filename_only" != ".." ]]; then
    file_extension="${filename_only##*.}"
  fi
  local file_extension_lower
  file_extension_lower=$(echo "$file_extension" | tr '[:upper:]' '[:lower:]')

  if [ -z "$extensions_filter_csv" ]; then
    output_file_xml "$current_file_path"
    return
  fi

  IFS=',' read -ra TARGET_EXT_ARRAY <<< "$extensions_filter_csv"
  for target_ext_raw in "${TARGET_EXT_ARRAY[@]}"; do
    local target_ext_trimmed
    target_ext_trimmed=$(echo "$target_ext_raw" | awk '{$1=$1};1')
    local target_ext_cleaned="${target_ext_trimmed#.}"
    local target_ext_lower
    target_ext_lower=$(echo "$target_ext_cleaned" | tr '[:upper:]' '[:lower:]')
    if [ -n "$target_ext_lower" ] && [ "$file_extension_lower" == "$target_ext_lower" ]; then
      output_file_xml "$current_file_path"
      return
    fi
  done
}

# --- Проверка, нужно ли исключить файл по папке ---
is_excluded_path() {
  local path="$1"
  local excludes_csv="$2"
  [ -z "$excludes_csv" ] && return 1
  IFS=',' read -ra EXCL_ARR <<< "$excludes_csv"
  for excl_raw in "${EXCL_ARR[@]}"; do
    local excl_trimmed
    excl_trimmed=$(echo "$excl_raw" | awk '{$1=$1};1')
    [ -z "$excl_trimmed" ] && continue
    if [[ "$path" == *"/$excl_trimmed/"* ]]; then
      return 0
    fi
  done
  return 1
}

# --- Печать помощи ---
print_usage() {
  echo "Usage: $0 <file_or_folder_path> [-e|--extensions comma_separated_extensions] [-x|--exclude comma_separated_folders]" >&2
  echo "  -e, --extensions EXT_LIST   Comma-separated list of file extensions to process." >&2
  echo "  -x, --exclude EXCL_LIST     Comma-separated list of folder names to exclude from search." >&2
  echo "  -h, --help                  Show this help message." >&2
}

# --- Парсинг аргументов ---
EXTENSIONS_CSV=""
EXCLUDES_CSV=""
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--extensions)
      if [[ -n "$2" && "$2" != -* ]]; then
        EXTENSIONS_CSV="$2"; shift 2
      else
        echo "Error: missing argument for $1" >&2; print_usage; exit 1
      fi
      ;;
    -x|--exclude)
      if [[ -n "$2" && "$2" != -* ]]; then
        EXCLUDES_CSV="$2"; shift 2
      else
        echo "Error: missing argument for $1" >&2; print_usage; exit 1
      fi
      ;;
    -h|--help)
      print_usage; exit 0
      ;;
    -*)
      echo "Error: unknown option $1" >&2; print_usage; exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1"); shift
      ;;
  esac
done

if [ ${#POSITIONAL_ARGS[@]} -eq 0 ]; then
  echo "Error: no path provided" >&2; print_usage; exit 1
elif [ ${#POSITIONAL_ARGS[@]} -gt 1 ]; then
  echo "Error: too many paths provided" >&2; print_usage; exit 1
fi

TARGET_PATH="${POSITIONAL_ARGS[0]}"

# --- Начало вывода ---
echo "<files>"

if [ -f "$TARGET_PATH" ]; then
  # Одиночный файл
  print_progress 1 1 "$TARGET_PATH"
  if ! is_excluded_path "$TARGET_PATH" "$EXCLUDES_CSV"; then
    check_and_process_file "$TARGET_PATH" "$EXTENSIONS_CSV"
  fi

elif [ -d "$TARGET_PATH" ]; then
  # Директория
  total_files=$(find "$TARGET_PATH" -type f | wc -l)
  counter=0

  find "$TARGET_PATH" -type f -print0 | while IFS= read -r -d $'\0' found_file_path; do
    if is_excluded_path "$found_file_path" "$EXCLUDES_CSV"; then
      continue
    fi
    counter=$((counter + 1))
    print_progress "$counter" "$total_files" "$found_file_path"
    check_and_process_file "$found_file_path" "$EXTENSIONS_CSV"
  done

else
  echo "Error: '$TARGET_PATH' is not a valid file or directory" >&2
  exit 1
fi

# --- Закрываем XML и даём финальный переход ---
echo "</files>"
printf "\n" >&2

exit 0
