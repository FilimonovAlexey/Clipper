# Tahoe - Architecture Deep Dive

## 🏗️ Архитектурная схема

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                          │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ MenuBarView  │  │ SettingsView │  │ SearchBar    │         │
│  │              │  │              │  │              │         │
│  │ - Header     │  │ - Sliders    │  │ - TextField  │         │
│  │ - List       │  │ - Toggles    │  │ - Clear btn  │         │
│  │ - Footer     │  │ - Pickers    │  │              │         │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘         │
│         │                  │                                     │
│         └──────────────────┴──────────────┐                     │
└────────────────────────────────────────────┼─────────────────────┘
                                             │
                    ╔════════════════════════▼═══════════════════╗
                    ║          VIEWMODEL LAYER                   ║
                    ║                                            ║
                    ║    ┌──────────────────────────────┐       ║
                    ║    │   ClipboardManager           │       ║
                    ║    │   (@ObservableObject)        │       ║
                    ║    │                              │       ║
                    ║    │  @Published items: []        │       ║
                    ║    │  @Published searchText       │       ║
                    ║    │                              │       ║
                    ║    │  + addItem()                 │       ║
                    ║    │  + deleteItem()              │       ║
                    ║    │  + togglePin()               │       ║
                    ║    │  + copyItem()                │       ║
                    ║    │  + clearAll()                │       ║
                    ║    └────┬──────────────┬─────┬────┘       ║
                    ╚═════════┼══════════════┼═════┼═════════════╝
                              │              │     │
        ┌─────────────────────┴──┐   ┌───────┴─┐   └───────────┐
        │                        │   │         │               │
┌───────▼────────┐  ┌───────────▼───▼──┐  ┌───▼──────────┐  ┌─▼────────────┐
│ PasteboardMon  │  │ StorageManager    │  │ HotKeyMgr    │  │ AppSettings  │
│                │  │                   │  │              │  │              │
│ - Timer        │  │ - FileManager     │  │ - Carbon     │  │ - UserDef    │
│ - changeCount  │  │ - JSONEncoder     │  │ - EventLoop  │  │ - @Published │
│                │  │ - JSONDecoder     │  │              │  │              │
│ + start()      │  │ + save()          │  │ + register() │  │ + persist()  │
│ + stop()       │  │ + load()          │  │ + unregister │  │              │
└────────┬───────┘  └──────────┬────────┘  └──────────────┘  └──────────────┘
         │                     │
         ▼                     ▼
┌────────────────┐    ┌──────────────────┐
│ NSPasteboard   │    │ FileSystem       │
│ (macOS API)    │    │ ~/Library/...    │
└────────────────┘    └──────────────────┘
```

---

## 🔄 Data Flow

### 1. Clipboard Monitoring Flow

```
User копирует текст (⌘C)
         │
         ▼
┌─────────────────────┐
│  NSPasteboard       │
│  changeCount++      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ PasteboardMonitor   │
│ Timer (0.5s)        │
│ Checks changeCount  │
└──────────┬──────────┘
           │
           ▼ (if changed)
┌─────────────────────┐
│ Extract string      │
│ Validate (not empty)│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ ClipboardManager    │
│ addItem(content)    │
└──────────┬──────────┘
           │
           ├─────────────────┐
           │                 │
           ▼                 ▼
┌──────────────────┐  ┌──────────────┐
│ Update @Published│  │ StorageManager│
│ items array      │  │ save to JSON │
└─────────┬────────┘  └──────────────┘
          │
          ▼
┌──────────────────┐
│ SwiftUI          │
│ Auto-redraws     │
│ UI               │
└──────────────────┘
```

### 2. User Interaction Flow

```
User clicks item in list
         │
         ▼
┌─────────────────────┐
│ ClipboardItemRow    │
│ onTapGesture        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ ClipboardManager    │
│ copyItem(id)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ NSPasteboard        │
│ clearContents()     │
│ setString()         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Haptic Feedback     │
│ NSHapticFeedback    │
└─────────────────────┘
```

### 3. Search Flow

```
User types in SearchBar
         │
         ▼
┌─────────────────────┐
│ @Binding text       │
│ (two-way binding)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ ClipboardManager    │
│ @Published          │
│ searchText updates  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Computed property   │
│ filteredItems       │
│ recalculates        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ SwiftUI List        │
│ Re-renders with     │
│ filtered items      │
└─────────────────────┘
```

### 4. Persistence Flow

```
App launches
     │
     ▼
┌─────────────────────┐
│ AppDelegate         │
│ didFinishLaunching  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ ClipboardManager    │
│ init()              │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ StorageManager      │
│ load()              │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Read JSON file      │
│ ~/Library/App.../   │
│ clipboard_hist.json │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ JSONDecoder         │
│ decode to           │
│ [ClipboardItem]     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ @Published items    │
│ populated           │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ UI shows history    │
└─────────────────────┘

When data changes:
    items.append()
         │
         ▼
    saveHistory()
         │
         ▼
    StorageManager.save()
         │
         ▼
    JSONEncoder → File
```

---

## 🧩 Component Dependencies

```
TahoeApp
    ├── depends on: AppDelegate
    │
    └── AppDelegate
            ├── creates: ClipboardManager
            │               ├── depends on: AppSettings
            │               ├── depends on: PasteboardMonitor
            │               └── depends on: StorageManager
            │
            ├── creates: HotKeyManager
            │               └── depends on: Carbon API
            │
            └── creates: MenuBarView
                            ├── uses: ClipboardManager (@ObservedObject)
                            ├── uses: AppSettings (@ObservedObject)
                            └── contains:
                                    ├── SearchBar
                                    ├── ClipboardItemRow (ForEach)
                                    └── SettingsView (sheet)
```

---

## 📊 State Management

### ObservableObject Pattern

```swift
// PUBLISHER (ViewModel)
@MainActor
class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var searchText: String = ""

    // When these change → SwiftUI auto-updates
}

// SUBSCRIBER (View)
struct MenuBarView: View {
    @ObservedObject var clipboardManager: ClipboardManager

    var body: some View {
        // UI automatically rebuilds when @Published properties change
        List(clipboardManager.filteredItems) { ... }
    }
}
```

### Binding Pattern

```swift
// PARENT
struct MenuBarView: View {
    @ObservedObject var clipboardManager: ClipboardManager

    var body: some View {
        SearchBar(text: $clipboardManager.searchText)
        //              ^ Binding: two-way sync
    }
}

// CHILD
struct SearchBar: View {
    @Binding var text: String  // Bidirectional

    var body: some View {
        TextField("Search", text: $text)
        // User types → parent's searchText updates
    }
}
```

---

## 🔐 Thread Safety

### @MainActor

```swift
@MainActor  // All methods run on main thread
class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []

    // Safe UI updates
    func addItem(_ content: String) {
        items.insert(ClipboardItem(content: content), at: 0)
        // @Published → triggers UI update on main thread
    }
}
```

### Background to Main

```swift
// In PasteboardMonitor
Timer.scheduledTimer { [weak self] _ in
    // Running on Timer's thread

    if let newContent = /* check pasteboard */ {
        Task { @MainActor in
            // Switch to main thread
            self?.clipboardManager.addItem(newContent)
        }
    }
}
```

---

## 💾 Data Models

### ClipboardItem

```swift
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID           // Unique identifier
    let content: String    // The actual text
    let timestamp: Date    // When copied
    var isPinned: Bool     // Pin state

    // Computed properties (not stored)
    var preview: String     // First 50 chars
    var relativeTime: String  // "5m ago"
}
```

**Storage format (JSON):**
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "content": "import SwiftUI",
  "timestamp": "2025-01-15T10:30:00Z",
  "isPinned": false
}
```

### AppSettings

```swift
class AppSettings: ObservableObject {
    @Published var itemLimit: Int {
        didSet { UserDefaults.standard.set(itemLimit, forKey: "itemLimit") }
    }

    @Published var launchAtLogin: Bool {
        didSet { /* save + apply */ }
    }

    @Published var appearanceMode: AppearanceMode {
        didSet { /* save + apply */ }
    }
}
```

**Storage:** UserDefaults (lightweight preferences)

---

## 🎯 Design Patterns

### 1. MVVM (Model-View-ViewModel)

```
MODEL               VIEWMODEL              VIEW
┌────────────┐      ┌─────────────┐       ┌──────────┐
│ClipboardIte│◄─────│Clipboard    │◄──────│MenuBar   │
│            │      │Manager      │       │View      │
│- id        │      │             │       │          │
│- content   │      │@Published   │       │@Observed │
│- timestamp │      │items        │       │Object    │
└────────────┘      └─────────────┘       └──────────┘
     ▲                     ▲
     │                     │
     │              ┌──────┴──────┐
     │              │             │
     │         ┌────▼────┐  ┌─────▼─────┐
     │         │Storage  │  │Pasteboard │
     │         │Manager  │  │Monitor    │
     │         └─────────┘  └───────────┘
     │
     └─────(pure data, no logic)
```

### 2. Observer Pattern

```swift
// Subject (Observable)
class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    // Publishes changes to observers
}

// Observer (View)
struct MenuBarView: View {
    @ObservedObject var manager: ClipboardManager
    // Automatically re-renders on changes
}
```

### 3. Delegate Pattern

```swift
// In AppDelegate
class AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHotKeys()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cleanup()
    }
}
```

### 4. Callback Pattern

```swift
// Service with callback
pasteboardMonitor.startMonitoring { content in
    // Called when new content detected
    clipboardManager.addItem(content)
}

hotKeyManager.register(.toggleWindow) {
    // Called when ⌘⇧V pressed
    togglePopover()
}
```

---

## ⚡ Performance Optimizations

### 1. Lazy Loading

```swift
// Only renders visible rows
LazyVStack {
    ForEach(filteredItems) { item in
        ClipboardItemRow(item: item)
    }
}
```

### 2. Computed Properties

```swift
// Recalculated only when dependencies change
var filteredItems: [ClipboardItem] {
    if searchText.isEmpty {
        return items  // Fast path
    }
    return items.filter { $0.content.contains(searchText) }
}
```

### 3. Efficient Polling

```swift
// Check changeCount instead of reading content every time
guard pasteboard.changeCount != lastChangeCount else {
    return  // No work needed
}
lastChangeCount = pasteboard.changeCount
// Only now read content
```

### 4. Item Limit

```swift
// Prevent unbounded growth
if items.count > limit {
    items = Array(items.prefix(limit))
}
```

---

## 🔒 Memory Management

### Weak References

```swift
// Prevent retain cycles
Timer.scheduledTimer { [weak self] _ in
    self?.checkPasteboard()
    // self is weak → no cycle
}

hotKeyManager.register(.toggleWindow) { [weak self] in
    self?.togglePopover()
}
```

### Automatic Cleanup

```swift
deinit {
    // Called when object is deallocated
    timer?.invalidate()
    eventMonitor?.stop()
}
```

---

## 🧪 Testability

Architecture позволяет легкое тестирование:

### Protocol-based mocking

```swift
// Original
class StorageManager {
    func save(_ items: [ClipboardItem]) { ... }
    func load() -> [ClipboardItem] { ... }
}

// For testing, create protocol:
protocol StorageProtocol {
    func save(_ items: [ClipboardItem])
    func load() -> [ClipboardItem]
}

// Mock implementation
class MockStorage: StorageProtocol {
    var savedItems: [ClipboardItem] = []

    func save(_ items: [ClipboardItem]) {
        savedItems = items
    }

    func load() -> [ClipboardItem] {
        return savedItems
    }
}

// Test
func testSave() {
    let mock = MockStorage()
    let manager = ClipboardManager(storage: mock)

    manager.addItem("test")
    XCTAssertEqual(mock.savedItems.count, 1)
}
```

---

## 📈 Scalability

### Current limits:
- **Items:** 50-500 (configurable)
- **Memory:** ~25-30 MB for 500 items
- **Search:** O(n) linear scan (fast enough for 500 items)

### For scaling to 10,000+ items:

1. **Database:** CoreData or SQLite
2. **Pagination:** Load chunks of 50
3. **Full-text search:** FTS5 in SQLite
4. **Indexing:** B-tree for fast lookups

---

## 🎨 UI Architecture

### SwiftUI Composition

```
MenuBarView
├── VStack
│   ├── Header (HStack)
│   │   ├── Icon + Title
│   │   └── Item count
│   │
│   ├── SearchBar
│   │   └── TextField + Clear button
│   │
│   ├── Content (conditional)
│   │   ├── if empty → EmptyState
│   │   └── else → ScrollView
│   │               └── LazyVStack
│   │                   └── ForEach(ClipboardItemRow)
│   │
│   └── Footer (HStack)
│       ├── Settings button
│       ├── Clear All button
│       └── Quit button
│
└── .sheet(isPresented: $showingSettings)
    └── SettingsView
```

---

## 🔧 Configuration Points

Легко изменяемые параметры:

| Параметр | Файл | Строка |
|----------|------|--------|
| Polling interval | PasteboardMonitor.swift | `0.5` seconds |
| Default item limit | AppSettings.swift | `100` |
| Popover size | MenuBarView.swift | `380x500` |
| Preview length | ClipboardItem.swift | `50` chars |
| Hot key combos | HotKeyManager.swift | ⌘⇧V, ⌘⇧C |

---

## 🎯 Summary

**Tahoe** использует современную iOS/macOS архитектуру:

✅ **MVVM** - четкое разделение concerns
✅ **Reactive** - автоматические UI updates
✅ **Modular** - легко тестируется и расширяется
✅ **Performant** - оптимизирован для macOS
✅ **Maintainable** - читаемый, документированный код

Архитектура позволяет легко добавлять новые features без изменения существующего кода (Open/Closed Principle).
