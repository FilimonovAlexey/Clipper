# Tahoe - Навигация по проекту

Полный индекс всех файлов проекта с описанием и метриками.

---

## 📁 Структура проекта

```
TahoeApp/
├── 📱 Приложение (1 файл, 141 LOC)
├── 📦 Models (2 файла, 139 LOC)
├── 🧠 ViewModels (1 файл, 151 LOC)
├── 🎨 Views (4 файла, 437 LOC)
├── ⚙️ Services (3 файла, 247 LOC)
├── 🔧 Config (2 файла, 40 LOC)
└── 📚 Docs (6 файлов, 1758 LOC)

ИТОГО: 13 Swift файлов, 1115 LOC
       8 документов, 2913 строк
```

---

## 🚀 Быстрый старт

Новичкам рекомендуется читать в таком порядке:

1. **[QUICKSTART.md](#quickstartmd)** - Запуск за 5 минут
2. **[README.md](#readmemd)** - Основная документация
3. **[TahoeApp.swift](#tahoeappswift)** - Точка входа
4. **[PROJECT_OVERVIEW.md](#project_overviewmd)** - Технический обзор

---

## 📱 Основное приложение

### TahoeApp.swift
**Строк:** 141 | **Роль:** Entry point, AppDelegate

**Что внутри:**
- `@main struct TahoeApp: App` - SwiftUI App lifecycle
- `class AppDelegate: NSApplicationDelegate` - Главный делегат
- Создание NSStatusItem (menu bar icon)
- Управление NSPopover (show/hide)
- Регистрация hot keys
- Lifecycle management

**Ключевые методы:**
- `applicationDidFinishLaunching()` - инициализация
- `setupMenuBar()` - создание menu bar item
- `setupHotKeys()` - регистрация ⌘⇧V, ⌘⇧C
- `togglePopover()` - открыть/закрыть окно

**Зависимости:** ClipboardManager, AppSettings, HotKeyManager

---

## 📦 Models (Модели данных)

### ClipboardItem.swift
**Строк:** 57 | **Роль:** Модель элемента истории

**Структура:**
```swift
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date
    var isPinned: Bool
}
```

**Computed properties:**
- `preview: String` - первые 50 символов
- `relativeTime: String` - "5m ago", "yesterday"

**Особенности:**
- Codable для JSON сериализации
- Identifiable для SwiftUI ForEach
- Equatable для сравнения

---

### AppSettings.swift
**Строк:** 82 | **Роль:** Настройки приложения

**@Published свойства:**
- `itemLimit: Int` (50-500)
- `launchAtLogin: Bool`
- `appearanceMode: AppearanceMode` (System/Light/Dark)

**Storage:** UserDefaults

**Особенности:**
- didSet для автосохранения
- applyAppearance() меняет NSApp.appearance

---

## 🧠 ViewModels (Бизнес-логика)

### ClipboardManager.swift
**Строк:** 151 | **Роль:** Главный ViewModel

**Роль:** Центральная бизнес-логика приложения

**@Published свойства:**
- `items: [ClipboardItem]` - вся история
- `searchText: String` - поисковый запрос

**Computed:**
- `filteredItems: [ClipboardItem]` - отфильтрованные + отсортированные

**Методы:**
- `addItem(_ content: String)` - добавить новый элемент
- `deleteItem(id: UUID)` - удалить элемент
- `togglePin(id: UUID)` - закрепить/открепить
- `copyItem(id: UUID)` - скопировать в буфер
- `clearAll()` - очистить всю историю

**Интеграции:**
- PasteboardMonitor - мониторинг буфера
- StorageManager - сохранение/загрузка
- AppSettings - настройки лимита

**Особенности:**
- @MainActor - все на главном потоке
- Автоматическое удаление дубликатов
- Enforce item limit
- Haptic feedback при копировании

---

## 🎨 Views (Интерфейс)

### MenuBarView.swift
**Строк:** 143 | **Роль:** Главное окно popover

**Структура:**
```
VStack
├── header (название + счетчик)
├── SearchBar
├── itemsList / emptyState
└── footer (настройки, очистка, quit)
```

**Размер:** 380x500 pt

**Особенности:**
- Условный рендеринг (empty state)
- LazyVStack для производительности
- Sheet для SettingsView
- Smooth animations

---

### ClipboardItemRow.swift
**Строк:** 79 | **Роль:** Строка элемента списка

**Компоненты:**
- Pin indicator (📌 если isPinned)
- Content (text + timestamp)
- Action buttons (pin, delete) - на hover

**Интерактивность:**
- onTapGesture → copy
- onHover → показать кнопки
- Transitions для плавности

**Особенности:**
- lineLimit(2) → lineLimit(nil) на hover
- Highlight background на hover
- SF Symbols для иконок

---

### SearchBar.swift
**Строк:** 42 | **Роль:** Компонент поиска

**Элементы:**
- Magnifying glass icon
- TextField
- Clear button (если текст не пустой)

**Binding:** Двусторонний с ClipboardManager.searchText

**Стиль:** Native macOS с .controlBackgroundColor

---

### SettingsView.swift
**Строк:** 173 | **Роль:** Окно настроек

**Секции:**
1. **History Limit**
   - Slider (50-500)
   - Текущее значение
   - Description

2. **Launch at Login**
   - Toggle switch
   - Description

3. **Appearance**
   - Segmented picker (System/Light/Dark)
   - Description

4. **Keyboard Shortcuts**
   - Read-only список хоткеев
   - Styled badges

**Размер:** 450x550 pt

**Особенности:**
- Form layout
- Grouped style
- Done button с keyboardShortcut

---

## ⚙️ Services (Сервисы)

### PasteboardMonitor.swift
**Строк:** 64 | **Роль:** Мониторинг NSPasteboard

**Как работает:**
1. Timer запускается каждые 0.5 сек
2. Проверяет pasteboard.changeCount
3. Если изменился → читает string content
4. Вызывает callback с новым контентом

**Методы:**
- `startMonitoring(interval:onChange:)` - запустить
- `stopMonitoring()` - остановить
- `checkPasteboard()` - внутренняя проверка

**Особенности:**
- Polling вместо notifications (NSPasteboard не имеет native events)
- Фильтрация пустых строк
- RunLoop.common для работы в background

---

### StorageManager.swift
**Строк:** 63 | **Роль:** Персистентность данных

**Методы:**
- `save(_ items: [ClipboardItem])` - сохранить в JSON
- `load() -> [ClipboardItem]` - загрузить из JSON
- `clearAll()` - удалить файл

**Путь:** `~/Library/Application Support/Tahoe/clipboard_history.json`

**Формат:** JSON с ISO8601 датами

**Error handling:**
- Try-catch для всех операций
- Graceful fallback к пустому массиву
- Автоматическое создание директорий

---

### HotKeyManager.swift
**Строк:** 120 | **Роль:** Глобальные горячие клавиши

**API:** Carbon Events (низкоуровневый macOS API)

**Зарегистрированные клавиши:**
- ⌘⇧V → Toggle window
- ⌘⇧C → Clear history

**Методы:**
- `register(_ hotKey:handler:)` - регистрация
- `unregisterAll()` - очистка

**Как работает:**
1. RegisterEventHotKey() - регистрирует комбинацию
2. InstallEventHandler() - устанавливает обработчик
3. При нажатии → вызывается handler closure
4. DispatchQueue.main.async для UI updates

**Особенности:**
- Legacy API но стабильный
- Работает глобально (даже когда app не в focus)
- Требует App Sandbox = OFF

---

## 🔧 Конфигурация

### Info.plist
**Строк:** 30 | **Роль:** Настройки приложения

**Ключевые параметры:**
- `LSUIElement = YES` - НЕ показывать в Dock
- `LSMinimumSystemVersion = 13.0` - macOS Ventura+
- `CFBundleIdentifier` - уникальный ID
- `NSHumanReadableCopyright` - copyright

---

### Tahoe.entitlements
**Строк:** 10 | **Роль:** Права доступа

**Entitlements:**
- `com.apple.security.app-sandbox = false` - выключен (для hot keys)
- `com.apple.security.automation.apple-events = true` - Apple Events

**Примечание:** Для App Store потребуется включить sandbox и изменить hot keys implementation.

---

## 📚 Документация (1758 строк)

### README.md
**Строк:** 202 | **Аудитория:** Пользователи и разработчики

**Содержание:**
- Описание и features
- Системные требования
- Установка (пошаговая)
- Использование (actions, hot keys, settings)
- Архитектура проекта
- Технические детали
- Возможные улучшения
- Troubleshooting

**Формат:** Markdown с таблицами и списками

---

### QUICKSTART.md
**Строк:** 129 | **Аудитория:** Новички

**Содержание:**
- Создание проекта за 5 минут
- Минимальная конфигурация
- Структура для копирования
- Проверка работоспособности
- Частые ошибки с решениями
- Минимальный Info.plist

**Цель:** Максимально быстро запустить приложение

---

### PROJECT_OVERVIEW.md
**Строк:** 415 | **Аудитория:** Разработчики

**Содержание:**
- Полное описание всех компонентов
- Архитектурные решения (почему так)
- Производительность и метрики
- Безопасность
- Edge cases и error handling
- Код стайл и качество
- Production checklist

**Цель:** Глубокое понимание проекта

---

### DEPLOYMENT.md
**Строк:** 353 | **Аудитория:** Release managers

**Содержание:**
- Сборка Release версии
- Подпись и notarization
- Создание DMG
- Launch at Login (SMAppService)
- Распространение (GitHub, Homebrew, App Store)
- Версионирование
- Автообновления (Sparkle)
- Тестирование перед релизом
- Uninstall инструкции
- Маркетинг и продвижение
- Roadmap для v2.0

**Цель:** Production deployment

---

### ARCHITECTURE.md
**Строк:** 659 | **Аудитория:** Архитекторы

**Содержание:**
- Визуальные схемы архитектуры
- Data flow диаграммы
- Component dependencies
- State management
- Thread safety (@MainActor)
- Data models
- Design patterns (MVVM, Observer, Delegate)
- Performance optimizations
- Memory management
- Testability
- Scalability
- UI architecture
- Configuration points

**Цель:** Полное понимание архитектуры

---

### INDEX.md (этот файл)
**Строк:** ~300 | **Аудитория:** Навигация

**Содержание:**
- Полный индекс всех файлов
- Описание каждого файла
- Метрики (LOC, роль)
- Ключевые методы и свойства
- Рекомендации по чтению

---

## 📊 Статистика проекта

### Swift код

| Категория | Файлов | Строк | % |
|-----------|--------|-------|---|
| Views | 4 | 437 | 39% |
| Services | 3 | 247 | 22% |
| ViewModels | 1 | 151 | 14% |
| App | 1 | 141 | 13% |
| Models | 2 | 139 | 12% |
| **ИТОГО** | **13** | **1115** | **100%** |

### Документация

| Файл | Строк | Тема |
|------|-------|------|
| ARCHITECTURE.md | 659 | Архитектура |
| PROJECT_OVERVIEW.md | 415 | Обзор |
| DEPLOYMENT.md | 353 | Deployment |
| INDEX.md | ~300 | Навигация |
| README.md | 202 | Основное |
| QUICKSTART.md | 129 | Быстрый старт |
| **ИТОГО** | **~2058** | - |

### Конфигурация

| Файл | Строк | Назначение |
|------|-------|------------|
| Info.plist | 30 | App settings |
| Tahoe.entitlements | 10 | Permissions |

---

## 🎯 Рекомендуемый порядок изучения

### Для пользователей
1. README.md → использование
2. QUICKSTART.md → быстрый старт

### Для разработчиков (новичков)
1. QUICKSTART.md → запуск
2. README.md → features
3. TahoeApp.swift → entry point
4. Models/ → данные
5. Views/ → UI
6. PROJECT_OVERVIEW.md → детали

### Для разработчиков (опытных)
1. ARCHITECTURE.md → архитектура
2. Код в порядке: Models → Services → ViewModels → Views → App
3. PROJECT_OVERVIEW.md → детали реализации

### Для release managers
1. DEPLOYMENT.md → deployment
2. README.md → feature set
3. PROJECT_OVERVIEW.md → технические требования

---

## 🔍 Поиск по фичам

### Где реализовано...

**Мониторинг буфера обмена**
- `PasteboardMonitor.swift` - polling logic
- `ClipboardManager.swift:startMonitoring()` - интеграция

**Поиск**
- `MenuBarView.swift` - SearchBar компонент
- `ClipboardManager.swift:filteredItems` - логика фильтрации

**Персистентность**
- `StorageManager.swift` - save/load JSON
- `ClipboardManager.swift` - вызовы save/load

**Горячие клавиши**
- `HotKeyManager.swift` - Carbon Events API
- `TahoeApp.swift:setupHotKeys()` - регистрация

**Настройки**
- `AppSettings.swift` - модель
- `SettingsView.swift` - UI

**Pin функциональность**
- `ClipboardItem.swift:isPinned` - поле
- `ClipboardManager.swift:togglePin()` - логика
- `ClipboardItemRow.swift` - UI (pin button)

**Темы**
- `AppSettings.swift:appearanceMode` - настройка
- `AppSettings.swift:applyAppearance()` - применение

---

## 🎨 UI компоненты

| Компонент | Файл | Размер | Особенности |
|-----------|------|--------|-------------|
| Main Window | MenuBarView.swift | 380x500 | Popover, transient |
| Settings | SettingsView.swift | 450x550 | Sheet modal |
| Item Row | ClipboardItemRow.swift | Auto | Hover effects |
| Search Bar | SearchBar.swift | Auto | Two-way binding |

---

## 🔗 Зависимости между файлами

```
TahoeApp.swift
    ↓
    ├─→ ClipboardManager (owns)
    │       ↓
    │       ├─→ AppSettings (uses)
    │       ├─→ PasteboardMonitor (owns)
    │       └─→ StorageManager (owns)
    │
    ├─→ HotKeyManager (owns)
    │
    └─→ MenuBarView (hosts)
            ↓
            ├─→ ClipboardManager (observes)
            ├─→ AppSettings (observes)
            ├─→ SearchBar (embeds)
            ├─→ ClipboardItemRow (embeds many)
            └─→ SettingsView (sheet)
```

---

## 💡 Советы по модификации

### Хочу добавить новую фичу...

**Новый тип контента (изображения)**
1. Расширить `ClipboardItem` → добавить `imageData: Data?`
2. Изменить `PasteboardMonitor` → проверять `.png`, `.tiff`
3. Обновить `ClipboardItemRow` → показывать Image()
4. Изменить `StorageManager` → кодировать Data

**Новый hot key**
1. Добавить case в `HotKeyManager.HotKey` enum
2. Определить keyCode и modifiers
3. Зарегистрировать в `TahoeApp.setupHotKeys()`

**Новая настройка**
1. Добавить @Published в `AppSettings`
2. Добавить UI в `SettingsView`
3. Использовать в `ClipboardManager` или другом компоненте

---

## 🚀 Быстрые ссылки

- [README](README.md) - Основная документация
- [QUICKSTART](QUICKSTART.md) - Запуск за 5 минут
- [ARCHITECTURE](ARCHITECTURE.md) - Архитектура
- [PROJECT_OVERVIEW](PROJECT_OVERVIEW.md) - Технический обзор
- [DEPLOYMENT](DEPLOYMENT.md) - Production deployment

---

**Версия:** 1.0
**Последнее обновление:** 2025-01-15
**Всего файлов:** 21 (13 Swift + 8 docs/config)
**Всего строк:** 3173+ LOC
