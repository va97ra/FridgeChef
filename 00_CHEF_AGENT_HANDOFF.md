# FridgeChef Chef Agent Handoff

Краткий handoff для следующих агентов. Читать до погружения в код.

## 0. Обязательное правило обновления

Каждый следующий агент обязан обновлять этот файл после своей итерации, если он:

- добавил новое семейство блюд
- изменил chef rules, validator, engine или roadmap
- поменял статус покрытия в `russian_cuisine_coverage.dart`
- изменил рекомендуемый следующий шаг

Если старый текст больше не соответствует коду, его нужно переписать или заменить, а не оставлять рядом как исторический мусор.

Цель файла:

- давать следующему агенту актуальное состояние проекта
- не заставлять его заново перечитывать всю кодовую базу
- не накапливать устаревшие указания

## 1. Что это за стадия проекта

Проект уже находится не на стадии "каталог рецептов". Внутри есть офлайн-шеф с:

- семействами блюд
- blueprint-ами генерации
- доменными валидаторами техники и структуры
- ранжированием по chef rules
- тестами на правильные и неправильные варианты

Главная цель: усиливать кулинарное понимание, а не просто добавлять новые рецепты.

## 2. Главные source of truth

Если контекст заканчивается, сначала читай эти файлы:

- `AGENTS.md`
- `00_PROJECT_MASTER_SPEC.md`
- `lib/features/recipes/domain/russian_cuisine_coverage.dart`
- `lib/features/recipes/domain/offline_chef_blueprints.dart`
- `lib/features/recipes/domain/chef_dish_validator.dart`
- `lib/features/recipes/domain/offline_chef_engine.dart`
- `lib/features/recipes/domain/chef_rules.dart`

Ключевой roadmap-файл: `lib/features/recipes/domain/russian_cuisine_coverage.dart`

Правило продолжения:

- если не знаешь, что делать дальше, продолжай с первой записи в `russian_cuisine_coverage`, у которой `status != covered`

## 3. Текущее состояние русской кухни

Срез на 2026-03-18:

- `covered`: 36
- `blockedByCatalog`: 14
- `missing`: 3

Покрыты отдельными семействами, а не только общими шаблонами:

- оливье
- винегрет
- щи
- борщ
- уха
- рассольник
- окрошка на кефире
- окрошка на квасе
- солянка
- щавелевые щи
- свекольник
- макароны по-флотски
- гречка по-домашнему
- творожная запеканка
- пирог с капустой и яйцом
- блины
- оладьи
- печеночные оладьи
- печеночный торт
- сырники
- драники
- каши
- голубцы и ленивые голубцы
- тефтели
- котлетный домашний ужин
- зразы
- биточки
- жаркое
- гуляш
- бефстроганов
- тушеная капуста

Следующие реальные кандидаты без расширения каталога:

- `charlotte`
- `sauerkraut_preserve`
- `lightly_salted_cucumbers`

Крупные блокеры каталога:

- семейства на тесте и лепке: пельмени, вареники, пирожки, кулебяка
- слоеные праздничные салаты и рыбные холодные блюда
- напитки и заготовки, которым нужен отдельный preserve/drink modeling

## 4. Что было сделано в этой итерации

Закрыто новое семейство: `liverCake` / `liver_cake`

Что добавлено:

- новый `ChefDishFamily.liverCake`
- новый `ChefStepStyle.liverCake`
- отдельный blueprint для печеночного торта
- отдельная генерация шагов в engine
- отдельная валидация layered cold appetizer техники и анти-дрейф checks
- отдельное family-specific reasoning в `chef_rules`
- покрытие в roadmap как `covered`
- позитивные и негативные тесты

Смысл семейства:

- это не "печень с майонезом как угодно"
- это холодная слоеная закуска из тонких печеночных коржей
- основа должна собираться из печени, яйца и муки
- обязательна отдельная луково-морковная прослойка
- обязательна майонезная или сметанная мягкая прослойка
- коржи должны жариться отдельно, а потом охлаждаться
- подача должна быть холодной или прохладной, не горячей со сковороды
- блюдо не должно превращаться в одну запеченную массу

## 5. Где именно править, если добавляешь новое семейство

Минимальный набор файлов почти всегда такой:

1. `lib/features/recipes/domain/offline_chef_blueprints.dart`
2. `lib/features/recipes/domain/offline_chef_engine.dart`
3. `lib/features/recipes/domain/chef_dish_validator.dart`
4. `lib/features/recipes/domain/russian_cuisine_coverage.dart`
5. `test/features/recipes/domain/chef_dish_validator_test.dart`
6. `test/features/recipes/domain/offline_chef_engine_test.dart`

Иногда дополнительно:

- `lib/features/recipes/domain/chef_rules.dart`
- `test/features/recipes/domain/chef_rules_test.dart`
- `test/features/recipes/domain/russian_cuisine_coverage_test.dart`

## 6. Как здесь правильно продолжать работу

Не начинай с "добавлю еще один recipe JSON".

Правильный порядок:

1. выбрать dish family из roadmap
2. проверить, хватает ли каталога продуктов
3. описать structural anchors
4. описать forbidden substitutions и bad drift
5. описать technique checks
6. встроить family в engine
7. добавить positive tests
8. добавить negative tests
9. обновить coverage manifest

## 7. Полезные правила по кулинарной логике

Не допускать:

- технически возможные, но кулинарно неверные варианты
- смешение холодного и горячего семейства без явной причины
- подмену семейства общей техникой "просто обжарь/смешай"
- сладость в savory family без специальной причины
- превращение порционного блюда в запеканку
- превращение structured dish в бесформенную массу

Ищем:

- баланс вкуса
- текстурную логику
- правильную последовательность
- защиту от лишней влаги или пересушивания
- правильный finish и serving logic

## 8. Команды проверки

`flutter` не лежит в PATH в этой среде. Используй локальный SDK из репозитория:

```powershell
./flutter/bin/flutter.bat test test/features/recipes/domain/chef_dish_validator_test.dart
./flutter/bin/flutter.bat test test/features/recipes/domain/chef_rules_test.dart
./flutter/bin/flutter.bat test test/features/recipes/domain/offline_chef_engine_test.dart
./flutter/bin/flutter.bat test test/features/recipes/domain/russian_cuisine_coverage_test.dart
```

Для форматирования:

```powershell
./flutter/bin/dart.bat format <files>
```

Замечание:

- строки вроде `reject pea_smoked_soup: ...` в `offline_chef_engine_test.dart` сейчас штатны; это диагностический вывод движка при отборе кандидатов

## 9. Следующий хороший шаг

Самый безопасный следующий шаг:

- `charlotte`, но только как отдельное fruit-bake family с яблочной структурой, а не как generic sweet bake

Самый полезный шаг для расширения модели:

- вынести отдельное preserve modeling перед `sauerkraut_preserve` и `lightly_salted_cucumbers`, иначе эти семьи будут притворяться обычными салатами/гарнирами

## 10. Быстрый вывод

Если времени мало:

- не перечитывай весь проект
- открой roadmap и продолжай с первого `missing`
- усиливай family reasoning
- обязательно добавляй negative tests
- не своди развитие шефа к росту количества рецептов
