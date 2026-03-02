# “Помоги приготовить-FridgeChef” — пошаговый план разработки (Flutter) + экраны + модули

Ты — senior Flutter developer. Твоя задача: не просто перечислить требования, а описать и выполнить разработку по шагам. Проект уже создан, папка существует, название приложения: “Помоги приготовить”.

Главное: код писать модульно (много файлов), без “всё в одном”. Начать с дизайна и структуры, потом экраны и логика.

---

## 0) Что делаем в итоге (MVP)

В приложении 3 главных раздела:

1) Главная (Home)

- красивая “сочная” стартовая страница
- большие анимированные кнопки:
  - “Мой холодильник”
  - “Полка” (специи/соль/сахар/приправы)
  - “Помоги приготовить”

1) Мой холодильник (Fridge)

- список продуктов
- плюсик в правом верхнем углу
- добавление продукта: название, вес/количество, единица, срок годности, калорийность

1) Полка (Shelf)

- список специй/приправ (обычно без веса, но можно добавить “есть/нет” или количество)
- плюсик для добавления

1) Помоги приготовить (Cook Ideas)

- приложение берёт “что есть в холодильнике + что есть на полке”
- показывает список рецептов, которые можно приготовить
- карточки рецептов красивые, с процентом совпадения и списком недостающего
- открытие рецепта: ингредиенты, порции, шаги приготовления

Работа офлайн: рецепты лежат в assets JSON.

---

## 1) Старт: проект, зависимости, ассеты

Предполагаем Flutter проект уже существует.

1.1 Добавить зависимости в pubspec.yaml:

- flutter_riverpod
- hive
- hive_flutter
- intl
- collection (если нужно)
- animations (для приятных переходов)
- google_fonts (если хотим красивый шрифт)

1.2 Добавить assets:

- assets/recipes/recipes.json
- assets/images/home_bg.png (если нет картинки — делаем градиент без файла)

1.3 Инициализация Hive:

- на старте приложения открыть boxes:
  - fridgeBox
  - shelfBox
  - settingsBox (опционально)

---

## 2) Архитектура и структура папок (сразу правильно)

lib/

- main.dart (только запуск, init, App)
- app/
  - app.dart (MaterialApp.router или MaterialApp)
  - routes.dart (роутинг)
- core/
  - theme/
    - app_theme.dart
    - tokens.dart (цвета/радиусы/отступы)
  - widgets/
    - app_scaffold.dart
    - primary_button.dart
    - glass_card.dart
    - app_text_field.dart
    - animated_tile.dart
  - utils/
    - units.dart
    - formatters.dart
- features/
  - home/
    - presentation/
      - home_screen.dart
      - widgets/
        - home_action_button.dart
  - fridge/
    - data/
      - fridge_repo.dart
      - fridge_hive_dto.dart
    - domain/
      - fridge_item.dart
    - presentation/
      - fridge_list_screen.dart
      - fridge_add_edit_screen.dart
      - providers.dart
      - widgets/
        - fridge_item_card.dart
  - shelf/
    - data/
      - shelf_repo.dart
      - shelf_hive_dto.dart
    - domain/
      - shelf_item.dart
    - presentation/
      - shelf_list_screen.dart
      - shelf_add_edit_screen.dart
      - providers.dart
      - widgets/
        - shelf_item_chip.dart
  - recipes/
    - data/
      - recipes_loader.dart (читает JSON из assets)
      - recipes_repo.dart
    - domain/
      - recipe.dart
      - recipe_ingredient.dart
      - recipe_match.dart
    - presentation/
      - cook_ideas_screen.dart
      - recipe_detail_screen.dart
      - providers.dart
      - widgets/
        - recipe_card.dart
        - match_bar.dart

Важно: данные и UI не смешивать.

---

## 3) Дизайн: “сочный” единый стиль (делаем первым)

3.1 Создать tokens.dart:

- цвета (primary/secondary/background/surface/text/warn)
- радиусы (12/16/24)
- отступы (8/12/16/20/24/32)

3.2 Создать app_theme.dart:

- ThemeData с:
  - ColorScheme
  - TextTheme (через GoogleFonts)
  - inputDecorationTheme (скруглённые поля)
  - elevatedButtonTheme (мягкие кнопки)
  - cardTheme (скругление + тень)

3.3 Компоненты:

- AppScaffold: рисует градиентный фон, SafeArea, общий padding
- GlassCard: “стеклянная” карточка (прозрачность + blur можно упрощённо)
- PrimaryButton: крупная кнопка с анимацией нажатия (scale)
- HomeActionButton: большая карточка-кнопка с иконкой и подписью

3.4 Анимации:

- на главной кнопки появляются с fade+slide
- нажатие: scale 0.98 + лёгкий haptic
- переходы между экранами: FadeThrough (animations package)

---

## 4) Экран: Главная (Home)

Создать home_screen.dart.

Содержимое:

- сверху: “Помоги приготовить” (заголовок) + подзаголовок “Добавь продукты и получи идеи”
- ниже 3 большие кнопки (карточки):
  1) “Мой холодильник”
  2) “Полка”
  3) “Помоги приготовить”

Кнопки ведут на:

- /fridge
- /shelf
- /cook

---

## 5) Модуль “Мой холодильник”

### 5.1 Модель домена

FridgeItem:

- id (uuid/string)
- name (строка)
- amount (double)
- unit (enum: g, kg, ml, l, pcs)
- expiresAt (DateTime?)
- caloriesPer100 (int?) или calories (int?) — выбери один подход

Рекомендация:

- caloriesPer100 = калорийность на 100г/100мл
- тогда можно считать примерную калорийность порции

### 5.2 Репозиторий

fridge_repo.dart:

- getAll()
- upsert(item)
- delete(id)

Данные хранить в Hive.

### 5.3 UI: список

fridge_list_screen.dart:

- красивый список карточек FridgeItemCard
- сверху AppBar с заголовком “Мой холодильник”
- справа иконка “+”
- пустое состояние: “Пока пусто — добавь продукты”

Карточка продукта показывает:

- название
- количество (например “200 г”)
- срок годности (если есть)
- калорийность (если есть)

### 5.4 UI: добавление

fridge_add_edit_screen.dart:
Форма:

- Название (TextField)
- Вес/количество (numeric)
- Единица (dropdown)
- Срок годности (date picker)
- Калорийность (numeric)

Кнопка “Сохранить”

- валидировать: название не пустое, количество > 0

После сохранения:

- вернуться назад
- список обновится через provider

---

## 6) Модуль “Полка” (специи/соль/сахар/травы)

Идея:
Полка — это “база”, которая часто используется и не ограничивает рецепты строго.
То есть специи могут быть “есть всегда”, но пусть пользователь сам отмечает.

### 6.1 Модель

ShelfItem:

- id
- name (строка)
- inStock (bool) или amount/unit (если хочешь количества)

Для MVP достаточно:

- name
- inStock

### 6.2 UI

shelf_list_screen.dart:

- список в виде чипов/плиток
- плюсик в AppBar
- переключатель наличия (toggle)

shelf_add_edit_screen.dart:

- название
- “есть в наличии” (по умолчанию true)

---

## 7) Модуль “Помоги приготовить” (подбор блюд)

### 7.1 База рецептов

assets/recipes/recipes.json

Структура рецепта:

- id
- title
- timeMin
- tags (например: quick, no_oven, one_pan)
- servingsBase
- ingredients:
  - name
  - amount
  - unit
  - required (true/false)
- steps (массив строк)
- optional: substitutions (словарь)

Начни с 30–50 простых рецептов (омлеты, салаты, паста, гречка, супы).

### 7.2 Загрузка рецептов

recipes_loader.dart:

- читает JSON из assets
- парсит в модели Recipe

### 7.3 Логика сопоставления (match)

Вычислять, что можно приготовить из:

- fridgeItems (основные продукты с количеством)
- shelfItems (специи как “доп. бонус”)

Алгоритм:

1) Для каждого рецепта:
2) Проверить каждый ингредиент:
   - если required и нет — добавить в missing
   - если есть, но amount недостаточно — missingAmount
3) Посчитать score:
   - requiredMatch = matchedRequired / requiredCount
   - optionalMatch = matchedOptional / optionalCount (если 0, считать 1)
   - score = 0.75*requiredMatch + 0.25*optionalMatch
   - если requiredMatch==1 добавить бонус 0.05
4) Отсортировать по score desc, потом timeMin asc

Показывать в карточке:

- “Совпадение: 80%”
- “Не хватает: молоко 200мл, сыр 50г”

### 7.4 UI: Cook Ideas

cook_ideas_screen.dart:

- заголовок “Помоги приготовить”
- кнопка “Подобрать”
- фильтры-чипы: “до 15 минут”, “без духовки”, “1 сковорода”
- список RecipeCard

При нажатии на рецепт → recipe_detail_screen.dart

### 7.5 UI: Recipe detail

recipe_detail_screen.dart:

- hero блок: название, время, теги
- переключатель порций (1/2/4/6)
- ингредиенты пересчитываются:
  newAmount = baseAmount * (targetServings / servingsBase)
- шаги приготовления (чекбоксы)

---

## 8) Обязательные переходы и UX

Home:

- Мой холодильник → список → + → добавление → сохранение → назад
- Полка → список → + → добавление
- Помоги приготовить → список рецептов → рецепт → шаги

Обязательно:

- приятные анимации (fade/slide, scale на кнопках)
- единый стиль (theme + общие виджеты)
- пустые состояния (EmptyState)

---

## 9) Что может быть упущено (предложение улучшений)

1) Редактирование продукта:

- на карточке “карандаш” или long-press → edit

1) Удаление:

- свайп в списке

1) Просрочка:

- если expiresAt < today — подсветить предупреждением

1) Поиск:

- поиск по списку продуктов и по рецептам

1) Умные категории:

- молочка, мясо, овощи (опционально)

Для MVP можно сделать позже.

---

## 10) Первые файлы, которые надо создать (чёткий старт)

1) core/theme/tokens.dart  
2) core/theme/app_theme.dart  
3) core/widgets/app_scaffold.dart  
4) app/app.dart  
5) app/routes.dart  
6) features/home/presentation/home_screen.dart  
7) features/fridge/* (models, repo, providers, screens)  
8) features/shelf/*  
9) features/recipes/* (loader, match, screens)

---

## 11) Критично важно

- Не писать огромные файлы.
- Все виджеты и логика разнесены по папкам.
- Начать с дизайна: токены, тема, базовые UI компоненты.
- После этого собирать экраны.

---

## 12) Команды (в README потом)

flutter pub get  
flutter run  

---

## Финальный вывод от тебя (как разработчика)

После генерации кода:

1) дерево файлов
2) что уже работает (по пунктам)
3) как добавить новый рецепт в recipes.json
4) как запустить проект
