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

- если не знаешь, что делать дальше, сначала посмотри на первую запись в `russian_cuisine_coverage`, у которой `status != covered`
- если первая непокрытая запись упирается в `blockedByCatalog`, не пытайся фейкнуть её общим blueprint-ом; смотри секцию "Следующий хороший шаг" и сначала снимай ближайший реальный блокер модели или каталога

## 3. Текущее состояние русской кухни

Срез на 2026-03-18:

- `covered`: 40
- `blockedByCatalog`: 13
- `missing`: 0

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
- шарлотка
- морс
- пирог с капустой и яйцом
- блины
- оладьи
- печеночные оладьи
- печеночный торт
- сырники
- драники
- квашеная капуста
- малосольные огурцы
- каши
- классические голубцы и ленивые голубцы
- тефтели
- котлетный домашний ужин
- зразы
- биточки
- жаркое
- гуляш
- бефстроганов
- тушеная капуста
- грибной суп
- гороховый суп с копченостями

Крупные блокеры каталога:

- семейства на тесте и лепке: пельмени, вареники, пирожки, кулебяка
- слоеные праздничные салаты и рыбные холодные блюда
- сладкие напитки и заготовки, где после `mors` ещё не хватает starch-thickened drink-dessert logic и sweet-preserve/jam logic

## 4. Что было сделано в этой итерации

Закрыто новое семейство: `mors`.

Что добавлено:

- в `assets/products/catalog_ru.json` добавлена berry expansion под `клюква`, `брусника`, `смородина`, `вишня`, `малина`, `черника`, `облепиха`
- в `ingredient_knowledge.dart` добавлены berry aliases, pairings и flavor vectors, чтобы ягоды распознавались не как шум, а как осмысленная кисло-сладкая база
- в `offline_chef_blueprints.dart` добавлен отдельный blueprint `mors` с узким ягодным контуром и лимонным опциональным акцентом
- в `offline_chef_engine.dart` добавлена отдельная `mors` step-logic: сок сначала отделяется, ягодная база прогревается отдельно, затем процеживается и охлаждается
- в `chef_dish_validator.dart` добавлены anchors и negative constraints для морса: он не должен съезжать в молочный коктейль, кисель или компотную варку
- в `chef_rules.dart` добавлены отдельные structure/balance/flavor/technique special-cases для `mors`, чтобы напиток не оценивался как слабое `general`-блюдо
- добавлены positive и negative tests для validator, rules и engine под `mors`
- прогнаны domain tests из handoff плюс `chef_catalog_quality_test.dart`

Смысл правки:

- `mors` не должен быть "любой сладкой ягодной водой"
- правильный морс держится на отдельной соковой и прогретой части, процеживании, охлаждении и чистом кисло-сладком профиле
- после покрытия `mors` berry layer перестал быть blocker; дальше реальный блокер уже не ягода сама по себе, а starch-thickened logic под `kissel`

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

- не трогать заново `mors`: базовый berry drink layer уже есть, с anti-compote и anti-milkshake guardrails
- следующий реальный шаг: отдельный `kissel` family на уже добавленном berry layer, но с новой starch-thickened drink-dessert logic

Самый полезный шаг для расширения модели:

- вынести отдельную густую drink-dessert модель под `kissel`, не фейкая её обычным морсом
- после `kissel` отдельно делать sweet preserve / jam logic, не притворяя её напитком, салатом или generic sweet sauce

## 10. Быстрый вывод

Если времени мало:

- не перечитывай весь проект
- открой roadmap и смотри на первый `status != covered`
- если там `blockedByCatalog`, не фейкни решение generic-логикой; сначала сними ближайший настоящий блокер
- усиливай family reasoning
- обязательно добавляй negative tests
- не своди развитие шефа к росту количества рецептов
