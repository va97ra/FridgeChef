# Помоги приготовить (FridgeChef)

MVP-приложение на Flutter для подбора блюд по содержимому холодильника и полки специй.

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
