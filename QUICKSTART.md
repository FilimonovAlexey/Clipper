# Tahoe - Быстрый старт

## Создание проекта за 5 минут

### Шаг 1: Создать новый Xcode проект

```bash
# В Xcode:
File → New → Project → macOS → App
Product Name: Tahoe
Interface: SwiftUI
Language: Swift
```

### Шаг 2: Настроить проект

1. **Target Settings** (выберите target "Tahoe"):
   - **General → Minimum Deployments:** macOS 13.0
   - **Signing & Capabilities:** Выключите App Sandbox (если включен)

2. **Info.plist** - добавьте:
   ```xml
   <key>LSUIElement</key>
   <true/>
   ```

### Шаг 3: Импортировать файлы

Скопируйте в проект:
```
TahoeApp.swift
Models/
  ├── ClipboardItem.swift
  └── AppSettings.swift
ViewModels/
  └── ClipboardManager.swift
Views/
  ├── MenuBarView.swift
  ├── ClipboardItemRow.swift
  ├── SearchBar.swift
  └── SettingsView.swift
Services/
  ├── PasteboardMonitor.swift
  ├── StorageManager.swift
  └── HotKeyManager.swift
```

### Шаг 4: Запустить

```bash
⌘R или Product → Run
```

Готово! Приложение появится в menu bar.

---

## Структура файлов для копирования

Если создаете проект вручную, используйте эту структуру:

```
YourProject/
├── Tahoe.xcodeproj
├── Tahoe/
│   ├── TahoeApp.swift          ← Главный файл
│   ├── Models/
│   │   ├── ClipboardItem.swift
│   │   └── AppSettings.swift
│   ├── ViewModels/
│   │   └── ClipboardManager.swift
│   ├── Views/
│   │   ├── MenuBarView.swift
│   │   ├── ClipboardItemRow.swift
│   │   ├── SearchBar.swift
│   │   └── SettingsView.swift
│   ├── Services/
│   │   ├── PasteboardMonitor.swift
│   │   ├── StorageManager.swift
│   │   └── HotKeyManager.swift
│   ├── Info.plist
│   └── Tahoe.entitlements
└── README.md
```

---

## Проверка работоспособности

После запуска:

1. ✅ Иконка появилась в menu bar (правый верхний угол)
2. ✅ Клик открывает окно с надписью "No clipboard history"
3. ✅ Скопируйте любой текст (⌘C) → должен появиться в списке
4. ✅ Клик по элементу → текст скопирован обратно
5. ✅ ⌘⇧V → окно открывается/закрывается
6. ✅ Поиск работает в реальном времени

---

## Частые ошибки

| Проблема | Решение |
|----------|---------|
| Приложение в Dock | Добавьте `LSUIElement = YES` в Info.plist |
| Не компилируется | Проверьте macOS deployment target (13.0+) |
| Хоткеи не работают | Выключите App Sandbox в Capabilities |
| История не сохраняется | Проверьте права в ~/Library/Application Support |

---

## Минимальный Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
```

---

Готово к использованию! 🎉
