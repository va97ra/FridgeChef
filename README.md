# Помоги приготовить (FridgeChef)

MVP-приложение на Flutter для подбора блюд по содержимому холодильника и полки специй.

## Быстрый вход для следующих агентов

Если задача связана с встроенным шефом, не начинайте с чтения всего проекта.
Сначала откройте `00_CHEF_AGENT_HANDOFF.md`, затем переходите к roadmap и доменным файлам шефа.
После изменений в логике шефа агент должен обновить этот handoff; если старое описание устарело, его нужно переписать, а не оставлять рядом.

## Структура проекта

```text
lib/
  app/
    app.dart
    routes.dart
  core/
    theme/
    utils/
    widgets/
  features/
    home/
    fridge/
    shelf/
    recipes/
assets/
  recipes/recipes.json
  images/
google_fonts/
  Nunito-*.ttf
```

## Что уже работает

1. Home-экран с анимированными CTA-кнопками: `Мой холодильник`, `Полка`, `Помоги приготовить`.
2. Модуль `Fridge`: список, добавление/редактирование/удаление, валидация формы, отображение срока и количества.
3. Модуль `Shelf`: список чипов, переключение `в наличии`, добавление/редактирование.
4. Модуль `Cook Ideas`: фильтры, расчёт совпадения по ингредиентам, список рецептов с missing-ингредиентами.
5. Экран рецепта: переключение порций, пересчёт ингредиентов, чеклист шагов.
6. Офлайн-работа с рецептами из `assets/recipes/recipes.json`.
7. Единый стиль через `tokens.dart`, `app_theme.dart`, общие виджеты.
8. Переходы экранов через `FadeThrough` (`animations` package).

## Как добавить новый рецепт

1. Откройте файл `assets/recipes/recipes.json`.
2. Добавьте новый объект в массив по схеме:

```json
{
  "id": "31",
  "title": "Название рецепта",
  "timeMin": 20,
  "tags": ["quick", "one_pan"],
  "servingsBase": 2,
  "ingredients": [
    {"name": "Яйцо", "amount": 2, "unit": "pcs", "required": true}
  ],
  "steps": [
    "Шаг 1",
    "Шаг 2"
  ]
}
```

3. Проверяйте единицы измерения: `g`, `kg`, `ml`, `l`, `pcs`.
4. Перезапустите приложение (`hot restart` или `flutter run`).

## Запуск проекта

```bash
flutter pub get
flutter run
```

Проверка качества:

```bash
flutter analyze
flutter test
```

Быстрый запуск браузерной release-сборки на локальном сервере:

```bat
.\scripts\run_web_release.cmd
```

По умолчанию приложение поднимется на `http://127.0.0.1:7361`, откроется в браузере, а лог сохранится в `web-release.log`.

Если нужен прямой вызов без `.cmd`, используйте `pwsh`, а не `powershell`, чтобы не открывались подряд `Windows PowerShell 5.1` и `PowerShell 7`:

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_web_release.ps1
```

Браузерный smoke без эмулятора:

```bat
.\scripts\run_web_smoke.cmd
```

Скрипт использует `flutter drive` + `integration_test` и гоняет browser smoke на `chrome` по умолчанию.

Альтернатива прямым вызовом:

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_web_smoke.ps1
```
