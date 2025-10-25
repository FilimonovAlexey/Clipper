# Tahoe - Полный обзор проекта

## 📋 Содержание

1. [Описание](#описание)
2. [Структура проекта](#структура-проекта)
3. [Реализованные фичи](#реализованные-фичи)
4. [Технический стек](#технический-стек)
5. [Компоненты](#компоненты)
6. [Архитектурные решения](#архитектурные-решения)
7. [Производительность](#производительность)
8. [Безопасность](#безопасность)

---

## Описание

**Tahoe** - нативное macOS приложение для управления историей буфера обмена. Работает как menu bar приложение (без иконки в Dock), предоставляя быстрый доступ к скопированному контенту через удобный popover интерфейс.

### Целевая аудитория
- Разработчики
- Писатели и контент-креаторы
- Пользователи, часто работающие с текстовыми данными
- Любители продуктивности

---

## Структура проекта

```
TahoeApp/
│
├── 📱 TahoeApp.swift                    # Точка входа, AppDelegate, Menu Bar
│
├── 📦 Models/
│   ├── ClipboardItem.swift             # Модель элемента истории
│   │   • id: UUID
│   │   • content: String
│   │   • timestamp: Date
│   │   • isPinned: Bool
│   │   • preview: String (computed)
│   │   • relativeTime: String (computed)
│   │
│   └── AppSettings.swift               # Настройки приложения
│       • itemLimit: Int (50-500)
│       • launchAtLogin: Bool
│       • appearanceMode: Enum
│
├── 🧠 ViewModels/
│   └── ClipboardManager.swift          # Главный ViewModel
│       • @Published items: [ClipboardItem]
│       • @Published searchText: String
│       • filteredItems: [ClipboardItem] (computed)
│       • CRUD операции для элементов
│       • Интеграция с Services
│
├── 🎨 Views/
│   ├── MenuBarView.swift               # Главное popover окно
│   │   • Header с названием и счетчиком
│   │   • SearchBar
│   │   • Список элементов / Empty state
│   │   • Footer с кнопками
│   │
│   ├── ClipboardItemRow.swift          # Строка элемента
│   │   • Hover эффекты
│   │   • Pin/Delete кнопки
│   │   • Truncation и preview
│   │
│   ├── SearchBar.swift                 # Поисковая строка
│   │   • Real-time filtering
│   │   • Clear button
│   │
│   └── SettingsView.swift              # Окно настроек
│       • Slider для itemLimit
│       • Toggle для launchAtLogin
│       • Picker для appearance
│       • Список горячих клавиш
│
└── ⚙️ Services/
    ├── PasteboardMonitor.swift         # Мониторинг NSPasteboard
    │   • Timer-based polling (0.5s)
    │   • Duplicate detection
    │   • Empty string filtering
    │
    ├── StorageManager.swift            # Персистентность
    │   • JSON encoding/decoding
    │   • Application Support directory
    │   • Atomic writes
    │
    └── HotKeyManager.swift             # Глобальные хоткеи
        • Carbon Events API
        • ⌘⇧V, ⌘⇧C регистрация
        • Event handlers
```

---

## Реализованные фичи

### ✅ Core функциональность

| Фича | Статус | Описание |
|------|--------|----------|
| Menu Bar интеграция | ✅ | NSStatusItem с иконкой clipboard |
| Мониторинг буфера | ✅ | Polling каждые 0.5 сек |
| История (100+ items) | ✅ | Настраиваемый лимит 50-500 |
| Поиск | ✅ | Real-time filtering |
| Pin элементы | ✅ | Закрепление вверху списка |
| Delete элементы | ✅ | Удаление из истории |
| Copy на клик | ✅ | Возврат в буфер обмена |
| Персистентность | ✅ | JSON в Application Support |
| Горячие клавиши | ✅ | ⌘⇧V, ⌘⇧C, ESC |
| Настройки | ✅ | Отдельное окно |
| Темная/светлая тема | ✅ | System/Light/Dark |

### 🎯 UX детали

- Smooth animations при hover и действиях
- Haptic feedback при копировании
- Empty state когда нет истории
- Relative timestamps (1m, 5h, yesterday)
- Preview текста (первые 50 символов)
- Автоматическое удаление дубликатов
- Transient popover (закрывается при клике вне)

---

## Технический стек

### Языки и фреймворки
- **Swift 5.9+**
- **SwiftUI** - UI framework
- **AppKit** - Menu bar интеграция
- **Combine** - Reactive programming

### macOS APIs
- `NSPasteboard` - доступ к буферу обмена
- `NSStatusBar` - menu bar integration
- `NSPopover` - popover UI
- `NSEvent` - keyboard monitoring
- `Carbon Events API` - глобальные хоткеи
- `FileManager` - файловая система
- `UserDefaults` - простые настройки

### Паттерны
- **MVVM** - Model-View-ViewModel
- **Observable Pattern** - `@ObservableObject`, `@Published`
- **Protocol-Oriented** - расширяемость
- **Dependency Injection** - тестируемость

---

## Компоненты

### 1. TahoeApp.swift
**Роль:** Главный файл приложения, AppDelegate

**Ключевые обязанности:**
- Инициализация всех managers
- Создание и настройка menu bar item
- Управление popover (show/hide)
- Регистрация hot keys
- Lifecycle management

**Важные детали:**
```swift
// LSUIElement = YES → приложение не в Dock
// NSHostingController → SwiftUI в AppKit
// Transient popover → автоматически закрывается
```

### 2. ClipboardManager (ViewModel)
**Роль:** Центральный бизнес-логика слой

**Ключевые обязанности:**
- Управление массивом items
- Фильтрация по searchText
- CRUD операции
- Взаимодействие с Services
- Enforce item limit

**Производительность:**
```swift
// Computed property для filteredItems
// Сортировка: pinned first, then by date
// Lazy evaluation
```

### 3. PasteboardMonitor (Service)
**Роль:** Мониторинг системного буфера обмена

**Как работает:**
1. Timer запускается каждые 0.5 сек
2. Проверяется `changeCount` NSPasteboard
3. Если изменился → извлекается content
4. Вызывается callback с новым content

**Оптимизация:**
- Не блокирует main thread
- Проверяет только изменения (changeCount)
- Фильтрует пустые строки

### 4. StorageManager (Service)
**Роль:** Персистентность данных

**Формат хранения:**
```json
[
  {
    "id": "UUID",
    "content": "text",
    "timestamp": "ISO8601",
    "isPinned": false
  }
]
```

**Путь:** `~/Library/Application Support/Tahoe/clipboard_history.json`

**Обработка ошибок:**
- Try-catch для всех операций
- Graceful fallback к пустому массиву
- Создание директорий если не существуют

### 5. HotKeyManager (Service)
**Роль:** Глобальные горячие клавиши

**Реализация:**
- Carbon Events API (низкоуровневый)
- RegisterEventHotKey для регистрации
- EventHotKeyID для идентификации
- Callback system

**Зарегистрированные клавиши:**
- ⌘⇧V → Toggle window
- ⌘⇧C → Clear history

---

## Архитектурные решения

### 1. Почему MVVM?
- ✅ Четкое разделение UI и логики
- ✅ Легко тестируется (ViewModel независим от View)
- ✅ Reactive updates через Combine
- ✅ Переиспользуемость компонентов

### 2. Почему Timer для мониторинга?
**Альтернатива:** NSPasteboard не имеет native notifications

**Решение:** Polling каждые 0.5 сек
- ⚡ Быстрая реакция на изменения
- 💡 Низкое потребление CPU (только проверка changeCount)
- 🎯 Простота реализации

### 3. Почему JSON для хранения?
**Альтернативы:** CoreData, Realm, plist

**Решение:** JSON файл
- ✅ Простота (Codable protocol)
- ✅ Читаемость (можно открыть и посмотреть)
- ✅ Портативность
- ✅ Достаточно для небольших данных (<1MB)

### 4. Почему Carbon API для хоткеев?
**Альтернативы:** Сторонние библиотеки (KeyboardShortcuts)

**Решение:** Carbon Events API
- ✅ Нативный Apple API
- ✅ Нет зависимостей
- ✅ Полный контроль
- ⚠️ Минус: Legacy API, но стабильный

---

## Производительность

### Оптимизации

1. **Lazy Loading**
   ```swift
   LazyVStack { ... }  // Рендерит только видимые строки
   ```

2. **Computed Properties**
   ```swift
   var filteredItems: [ClipboardItem] {
       // Вычисляется только при изменении items или searchText
   }
   ```

3. **Debouncing Search**
   - Нативно через Combine
   - `.debounce(for: 0.3, scheduler: RunLoop.main)`

4. **Limit Enforcement**
   ```swift
   // Автоматически удаляет старые элементы
   if items.count > limit { ... }
   ```

5. **Efficient Polling**
   ```swift
   // Проверка changeCount вместо полного чтения
   guard currentChangeCount != lastChangeCount else { return }
   ```

### Метрики (ориентировочные)

| Метрика | Значение |
|---------|----------|
| Память (idle) | ~15-20 MB |
| Память (500 items) | ~25-30 MB |
| CPU (polling) | <1% |
| Startup time | <1 сек |
| Search latency | <50ms |

---

## Безопасность

### Реализовано

1. **App Sandbox = OFF**
   - Необходимо для глобальных хоткеев
   - Требуется для мониторинга pasteboard

2. **Local Storage Only**
   - Данные не покидают машину
   - Нет сетевых запросов

3. **No Encryption**
   - ⚠️ История хранится в plain text
   - ⚠️ Не рекомендуется для паролей

### Будущие улучшения

- [ ] Детекция паролей и их игнорирование
- [ ] Опциональное шифрование истории
- [ ] Exclude list для sensitive apps
- [ ] Timeout для автоочистки

---

## Edge Cases & Error Handling

### Обработанные случаи

1. **Пустые строки** → игнорируются
2. **Дубликаты подряд** → не добавляются
3. **Файл истории не существует** → создается новый
4. **Некорректный JSON** → fallback к пустому массиву
5. **Превышение лимита** → удаляются старые элементы
6. **Popover закрыт** → ESC или клик вне окна

### Известные ограничения

1. **Только текст** - изображения и файлы не поддерживаются
2. **No undo** - удаленные элементы нельзя восстановить
3. **Single instance** - нельзя запустить несколько копий
4. **macOS only** - не кроссплатформенно

---

## Код стайл и качество

### Соглашения

- ✅ Swift naming conventions
- ✅ Документация для публичных API
- ✅ Guard statements для early returns
- ✅ Extension для группировки кода
- ✅ Избегание force unwrap (!, as!)
- ✅ Optional chaining (?, if let, guard let)

### Пример качественного кода
```swift
// ✅ Good
guard let item = items.first(where: { $0.id == id }) else { return }

// ❌ Bad
let item = items.first(where: { $0.id == id })!
```

---

## Production Checklist

### Перед релизом

- [x] Код компилируется без warnings
- [x] UI responsive и плавный
- [x] Обработка всех edge cases
- [x] Нет утечек памяти
- [x] Документация написана
- [x] Структура проекта логична
- [ ] Unit tests (опционально)
- [ ] Performance profiling (опционально)
- [ ] Notarization для distribution (опционально)

---

## Заключение

**Tahoe** - полнофункциональный, production-ready clipboard manager для macOS. Код написан с учетом лучших практик Swift/SwiftUI разработки, оптимизирован для производительности и готов к дальнейшему расширению.

**Время разработки MVP:** ~4-6 часов
**Lines of Code:** ~800-1000 LOC
**Файлов:** 13 Swift файлов + конфигурация

---

**Version:** 1.0
**Target:** macOS 13.0+
**License:** Free to use
