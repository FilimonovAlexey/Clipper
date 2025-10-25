# Tahoe - Deployment Guide

## Подготовка к релизу

### 1. Сборка Release версии

В Xcode:

1. **Product → Scheme → Edit Scheme**
2. Выберите **Run** → вкладка **Info**
3. **Build Configuration:** Release
4. **Product → Archive**
5. **Distribute App → Copy App**

### 2. Подпись приложения (опционально)

Для распространения вне App Store:

```bash
# Подписать приложение
codesign --force --deep --sign "Developer ID Application: Your Name" Tahoe.app

# Проверить подпись
codesign --verify --deep --strict Tahoe.app
spctl -a -v Tahoe.app
```

### 3. Notarization (macOS 10.15+)

Для избежания ошибки "App is damaged":

```bash
# 1. Создать ZIP архив
ditto -c -k --keepParent Tahoe.app Tahoe.zip

# 2. Отправить на notarization
xcrun notarytool submit Tahoe.zip \
  --apple-id "your@email.com" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait

# 3. Staple ticket
xcrun stapler staple Tahoe.app
```

### 4. Создание DMG

```bash
# Установить create-dmg (если нет)
brew install create-dmg

# Создать DMG
create-dmg \
  --volname "Tahoe Installer" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Tahoe.app" 175 190 \
  --hide-extension "Tahoe.app" \
  --app-drop-link 425 190 \
  "Tahoe-1.0.dmg" \
  "Tahoe.app"
```

---

## Launch at Login (SMAppService)

Для полноценного автозапуска нужен Login Item:

### Вариант 1: Service Management (macOS 13+)

1. Создайте новый Target: **File → New → Target → Launch Agent**

2. В main app добавьте код:
```swift
import ServiceManagement

func enableLaunchAtLogin() {
    do {
        try SMAppService.mainApp.register()
    } catch {
        print("Failed to register login item: \(error)")
    }
}

func disableLaunchAtLogin() {
    do {
        try SMAppService.mainApp.unregister()
    } catch {
        print("Failed to unregister login item: \(error)")
    }
}
```

3. Вызывайте в `AppSettings.launchAtLogin.didSet`

### Вариант 2: Sandbox (старый метод)

Используйте helper app с `SMLoginItemSetEnabled()` (deprecated но работает)

---

## Распространение

### Опция 1: GitHub Releases

1. Создайте репозиторий на GitHub
2. Соберите signed DMG
3. Создайте Release с тегом (v1.0)
4. Прикрепите DMG к релизу

```bash
gh release create v1.0 \
  --title "Tahoe v1.0" \
  --notes "Initial release" \
  Tahoe-1.0.dmg
```

### Опция 2: Homebrew Cask

Создайте `.rb` formula:

```ruby
cask "tahoe" do
  version "1.0"
  sha256 "checksum"

  url "https://github.com/yourname/tahoe/releases/download/v#{version}/Tahoe-#{version}.dmg"
  name "Tahoe"
  desc "Clipboard manager for macOS"
  homepage "https://github.com/yourname/tahoe"

  app "Tahoe.app"

  zap trash: [
    "~/Library/Application Support/Tahoe",
    "~/Library/Preferences/com.yourname.Tahoe.plist",
  ]
end
```

### Опция 3: Mac App Store

1. Включите App Sandbox
2. Добавьте необходимые entitlements
3. Пройдите App Review
4. Опубликуйте через App Store Connect

**Note:** Для App Store потребуются изменения:
- Включить App Sandbox
- Использовать другой метод для глобальных хоткеев
- Добавить Privacy descriptions

---

## Версионирование

Используйте Semantic Versioning:

- **1.0.0** - Initial release
- **1.1.0** - Minor features (images support)
- **1.0.1** - Bug fixes
- **2.0.0** - Breaking changes

Обновляйте в:
1. Info.plist → `CFBundleShortVersionString`
2. Info.plist → `CFBundleVersion` (build number)

---

## Автоматические обновления (Sparkle)

Для самоуправляемых обновлений:

```bash
# Добавить Sparkle framework
# https://sparkle-project.org

# Добавить в Info.plist
<key>SUFeedURL</key>
<string>https://yoursite.com/appcast.xml</string>
```

---

## Системные требования

Убедитесь, что в README указаны:

- **macOS:** 13.0 (Ventura) или новее
- **Архитектура:** Intel + Apple Silicon (Universal Binary)
- **Память:** ~20 MB
- **Диск:** ~5 MB

---

## Тестирование перед релизом

### Чек-лист

- [ ] Тест на чистой macOS 13.0 VM
- [ ] Тест на Apple Silicon (M1/M2/M3)
- [ ] Тест на Intel Mac
- [ ] Проверка подписи
- [ ] Проверка notarization
- [ ] Тест установки из DMG
- [ ] Тест автозапуска (Launch at Login)
- [ ] Проверка всех hot keys
- [ ] Stress test (500+ элементов)
- [ ] Memory leak test (Instruments)
- [ ] Проверка сохранения настроек
- [ ] Проверка удаления (все файлы очищены)

### Тестовые сценарии

1. **Базовый workflow:**
   - Установить приложение
   - Скопировать 10 разных текстов
   - Найти элемент через поиск
   - Закрепить (pin) элемент
   - Удалить элемент
   - Перезапустить → история сохранена

2. **Edge cases:**
   - Скопировать очень длинный текст (>10,000 символов)
   - Скопировать emoji и unicode
   - Скопировать пустую строку → должна игноритьс��
   - Скопировать одно и то же дважды → должен игнорироваться

3. **Performance:**
   - Добавить 500 элементов
   - Проверить scroll performance
   - Проверить поиск в 500 элементах
   - Мониторить CPU и память

---

## Uninstall

Пользователь должен уметь полностью удалить:

### Ручное удаление

```bash
# 1. Quit app
osascript -e 'quit app "Tahoe"'

# 2. Remove app
rm -rf /Applications/Tahoe.app

# 3. Remove data
rm -rf ~/Library/Application\ Support/Tahoe

# 4. Remove preferences
defaults delete com.yourname.Tahoe
```

### Автоматизированный скрипт

Создайте `uninstall.sh`:

```bash
#!/bin/bash
echo "Uninstalling Tahoe..."

# Kill app
killall Tahoe 2>/dev/null

# Remove files
rm -rf /Applications/Tahoe.app
rm -rf ~/Library/Application\ Support/Tahoe
rm -f ~/Library/Preferences/com.yourname.Tahoe.plist

echo "Tahoe has been uninstalled."
```

---

## Маркетинг

### Landing page

Создайте простую страницу с:
- Скриншоты UI
- Список фич
- Кнопка Download
- FAQ
- Changelog

### Продвижение

- [ ] Product Hunt launch
- [ ] Reddit r/macapps
- [ ] Hacker News Show HN
- [ ] Twitter/X announcement
- [ ] macOS subreddits
- [ ] Indie Hackers

---

## Мониторинг (опционально)

Для сбора anonymous usage stats:

```swift
// TelemetryDeck, PostHog, или свое решение
// НЕ собирать содержимое clipboard!

struct Analytics {
    static func track(_ event: String) {
        // Только events: app_opened, item_copied, search_used
    }
}
```

---

## Лицензия

Выберите лицензию:

- **MIT** - максимально открытая
- **GPL** - требует open source форков
- **Proprietary** - закрытый код

Добавьте файл `LICENSE`:

```
MIT License

Copyright (c) 2025 Your Name

Permission is hereby granted, free of charge...
```

---

## Roadmap для v2.0

- [ ] Image clipboard support
- [ ] iCloud sync
- [ ] Safari/Chrome extension
- [ ] Custom snippets
- [ ] Categories and tags
- [ ] Export to CSV
- [ ] Sensitive data filtering
- [ ] Keyboard-only navigation

---

**Готово к production deployment!** 🚀
