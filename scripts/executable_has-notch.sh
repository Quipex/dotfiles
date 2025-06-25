#!/bin/bash

# has_notch.sh
# Возвращает 'true', если у macOS устройства есть "чёлка" (notch), иначе 'false'.
# Основано на идентификаторе модели оборудования для максимальной точности.

# Получаем идентификатор модели
model=$(sysctl -n hw.model)

# Проверяем модель по списку известных устройств с "чёлкой"
case "$model" in
  # MacBook Pro (14" & 16", 2021, M1 Pro/Max)
  MacBookPro18,1|MacBookPro18,2|MacBookPro18,3|MacBookPro18,4)
    echo "true"
    ;;
  # MacBook Air (M2, 2022)
  Mac14,2)
    echo "true"
    ;;
  # MacBook Pro (14" & 16", 2023, M2 Pro/Max)
  Mac14,5|Mac14,6|Mac14,9|Mac14,10)
    echo "true"
    ;;
  # MacBook Air (15", M2, 2023)
  Mac14,15)
    echo "true"
    ;;
  # MacBook Air (13" & 15", M3, 2024)
  Mac15,1|Mac15,2)
    echo "true"
    ;;
  # MacBook Pro (14" & 16", 2023-2024, M3 series)
  Mac15,3|Mac15,4|Mac15,5|Mac15,6|Mac15,7|Mac15,8|Mac15,9|Mac15,10|Mac15,11)
    echo "true"
    ;;
  # Все остальные модели
  *)
    echo "false"
    ;;
esac