import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/recipes/domain/chef_dish_validator.dart';
import 'package:help_to_cook/features/recipes/domain/offline_chef_blueprints.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';

void main() {
  test('rejects olivier without potato anchor', () {
    final result = validateChefDish(
      blueprint: _blueprint('olivier'),
      recipe: const Recipe(
        id: 'olivier-no-potato',
        title: 'Оливье по-домашнему: Яйца и Огурцы',
        timeMin: 18,
        tags: ['salad'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Огурцы', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Горошек', amount: 120, unit: Unit.g),
          RecipeIngredient(name: 'Майонез', amount: 45, unit: Unit.g),
        ],
        steps: [
          'Подготовь и нарежь яйца, морковь и огурцы удобными кусочками.',
          'Сложи всё в большую миску и аккуратно перемешай.',
          'Перед подачей заправь салат через майонез.',
        ],
      ),
      recipeCanonicals: const {
        'яйцо',
        'морковь',
        'огурец',
        'горошек',
        'майонез'
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Оливье без картофеля теряет обязательную основу.'),
    );
  });

  test('rejects fish soup that does not add fish late', () {
    final result = validateChefDish(
      blueprint: _blueprint('ukha'),
      recipe: const Recipe(
        id: 'ukha-flat',
        title: 'Уха домашняя',
        timeMin: 34,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Рыба', amount: 500, unit: Unit.g),
          RecipeIngredient(name: 'Картофель', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Укроп', amount: 12, unit: Unit.g),
        ],
        steps: [
          'Подготовь рыбу, картофель и лук.',
          'Сложи всё в кастрюлю сразу и вари суп 25 минут.',
          'В самом конце добавь укроп и подавай.',
        ],
      ),
      recipeCanonicals: const {'рыба', 'картофель', 'лук', 'укроп'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Уха должна добавлять рыбу после овощной базы, а не варить всё вместе с начала.',
      ),
    );
  });

  test('rejects borscht without cabbage body', () {
    final result = validateChefDish(
      blueprint: _blueprint('borscht'),
      recipe: const Recipe(
        id: 'borscht-no-cabbage',
        title: 'Борщ по-домашнему',
        timeMin: 36,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Свекла', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Картофель', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Томатная паста', amount: 60, unit: Unit.g),
        ],
        steps: [
          'Подготовь свеклу, картофель, морковь и лук.',
          'Влей воду и вари суп 20-25 минут.',
          'В конце добавь сметану и подавай.',
        ],
      ),
      recipeCanonicals: const {
        'свекла',
        'картофель',
        'морковь',
        'лук',
        'томатная паста',
        'сметана',
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Борщу нужна капустная опора.'),
    );
  });

  test('rejects shchi that drift into beetroot borscht base', () {
    final result = validateChefDish(
      blueprint: _blueprint('shchi'),
      recipe: const Recipe(
        id: 'shchi-beet',
        title: 'Щи домашние',
        timeMin: 34,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Капуста', amount: 400, unit: Unit.g),
          RecipeIngredient(name: 'Свекла', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Картофель', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Подготовь капусту, свеклу, картофель и лук.',
          'Влей воду и вари суп 18-22 минуты.',
          'Перед подачей добавь сметану.',
        ],
      ),
      recipeCanonicals: const {
        'капуста',
        'свекла',
        'картофель',
        'лук',
        'сметана'
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Щи не должны уходить в свекольную основу борща.'),
    );
  });

  test('rejects solyanka without bright olive or lemon finish', () {
    final result = validateChefDish(
      blueprint: _blueprint('solyanka'),
      recipe: const Recipe(
        id: 'solyanka-flat',
        title: 'Солянка домашняя',
        timeMin: 32,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Колбаса', amount: 220, unit: Unit.g),
          RecipeIngredient(name: 'Соленые огурцы', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Томатная паста', amount: 60, unit: Unit.g),
        ],
        steps: [
          'Подготовь колбасу, огурцы и лук.',
          'Влей воду, добавь томатную пасту и вари солянку 14-16 минут.',
          'Сними с огня и подавай.',
        ],
      ),
      recipeCanonicals: const {'колбаса', 'огурец', 'лук', 'томатная паста'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Солянке нужен яркий соляно-кислый финиш через оливки или лимон.',
      ),
    );
  });

  test('rejects okroshka without chilled kefir assembly', () {
    final result = validateChefDish(
      blueprint: _blueprint('okroshka_kefir'),
      recipe: const Recipe(
        id: 'okroshka-hot',
        title: 'Окрошка на кефире',
        timeMin: 22,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Кефир', amount: 450, unit: Unit.ml),
          RecipeIngredient(name: 'Картофель', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Огурцы', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Укроп', amount: 12, unit: Unit.g),
        ],
        steps: [
          'Отвари картофель и яйца 10 минут.',
          'Нарежь огурцы и укроп.',
          'Смешай всё с кефиром и сразу подавай.',
        ],
      ),
      recipeCanonicals: const {'кефир', 'картофель', 'яйцо', 'огурец', 'укроп'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
          'Окрошка должна собираться через вливание кефира в холодную базу.'),
    );
    expect(
      result.violations,
      contains('Холодный суп должен явно подаваться охлаждённым.'),
    );
  });

  test('rejects kvass okroshka without kvass pour step', () {
    final result = validateChefDish(
      blueprint: _blueprint('okroshka_kvass'),
      recipe: const Recipe(
        id: 'okroshka-kvass-flat',
        title: 'Окрошка на квасе',
        timeMin: 22,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Квас', amount: 500, unit: Unit.ml),
          RecipeIngredient(name: 'Картофель', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Огурцы', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Укроп', amount: 12, unit: Unit.g),
        ],
        steps: [
          'Отвари картофель и яйца 10 минут, затем остуди.',
          'Нарежь огурцы и укроп.',
          'Смешай всё и подавай холодной.',
        ],
      ),
      recipeCanonicals: const {'квас', 'картофель', 'яйцо', 'огурец', 'укроп'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Окрошка на квасе должна собираться через вливание кваса в холодную базу.',
      ),
    );
  });

  test('rejects blini without rested batter', () {
    final result = validateChefDish(
      blueprint: _blueprint('blini'),
      recipe: const Recipe(
        id: 'blini-rushed',
        title: 'Блины домашние',
        timeMin: 10,
        tags: ['breakfast'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Мука', amount: 140, unit: Unit.g),
          RecipeIngredient(name: 'Молоко', amount: 250, unit: Unit.ml),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
        ],
        steps: [
          'Сразу смешай муку, молоко и яйца в тесто.',
          'Жарь блины на сковороде по 1-2 минуты с каждой стороны.',
          'Подавай горячими.',
        ],
      ),
      recipeCanonicals: const {'мука', 'молоко', 'яйцо'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Блинному тесту нужно коротко постоять перед жаркой.'),
    );
  });

  test('rejects oladyi without thick portioned frying', () {
    final result = validateChefDish(
      blueprint: _blueprint('oladyi'),
      recipe: const Recipe(
        id: 'oladyi-flat',
        title: 'Оладьи на кефире',
        timeMin: 12,
        tags: ['breakfast'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Мука', amount: 150, unit: Unit.g),
          RecipeIngredient(name: 'Кефир', amount: 250, unit: Unit.ml),
          RecipeIngredient(name: 'Яйца', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Размешай муку, кефир и яйца в тесто.',
          'Вылей всё на сковороду одним слоем и быстро поджарь.',
          'Подавай горячим.',
        ],
      ),
      recipeCanonicals: const {'мука', 'кефир', 'яйцо'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Оладьи требуют более густое тесто, а не жидкую блинную массу.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Оладьи должны выкладываться на сковороду небольшими порциями.',
      ),
    );
  });

  test('rejects syrniki that drift into oven technique', () {
    final result = validateChefDish(
      blueprint: _blueprint('syrniki'),
      recipe: const Recipe(
        id: 'syrniki-oven',
        title: 'Сырники',
        timeMin: 18,
        tags: ['breakfast'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Творог', amount: 360, unit: Unit.g),
          RecipeIngredient(name: 'Яйца', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Соедини творог с яйцом и собери массу.',
          'Разложи массу по форме и запекай 20 минут в духовке.',
          'Подавай тёплыми.',
        ],
      ),
      recipeCanonicals: const {'творог', 'яйцо'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Сырники не должны уходить в запекание.'),
    );
  });

  test('rejects syrniki that drift into spooned batter technique', () {
    final result = validateChefDish(
      blueprint: _blueprint('syrniki'),
      recipe: const Recipe(
        id: 'syrniki-batter',
        title: 'Сырники',
        timeMin: 16,
        tags: ['breakfast'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Творог', amount: 360, unit: Unit.g),
          RecipeIngredient(name: 'Яйца', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Размешай творог с яйцом в густое тесто.',
          'Выкладывай массу ложкой на сковороду и жарь.',
          'Подавай горячими.',
        ],
      ),
      recipeCanonicals: const {'творог', 'яйцо'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Сырники не должны жариться как оладьи из жидкой массы.'),
    );
    expect(
      result.violations,
      contains('Сырники должны формоваться руками в небольшие шайбы.'),
    );
  });

  test('rejects lazy cabbage rolls without rice structure', () {
    final result = validateChefDish(
      blueprint: _blueprint('lazy_cabbage_rolls'),
      recipe: const Recipe(
        id: 'lazy-cabbage-rolls-no-rice',
        title: 'Ленивые голубцы',
        timeMin: 28,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Фарш', amount: 420, unit: Unit.g),
          RecipeIngredient(name: 'Капуста', amount: 700, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Томатная паста', amount: 45, unit: Unit.g),
        ],
        steps: [
          'Подготовь капусту и лук, затем соедини их с фаршем.',
          'Добавь томатную пасту и туши ленивые голубцы под крышкой 18-22 минуты.',
          'Дай блюду постоять и подавай горячим.',
        ],
      ),
      recipeCanonicals: const {'фарш', 'капуста', 'лук', 'томатная паста'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Ленивым голубцам нужен рис для правильной структуры.'),
    );
  });

  test('rejects home cutlet dinner without garnish service', () {
    final result = validateChefDish(
      blueprint: _blueprint('kotlet_dinner'),
      recipe: const Recipe(
        id: 'cutlet-dinner-no-garnish',
        title: 'Котлеты по-домашнему',
        timeMin: 20,
        tags: ['stew'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Фарш', amount: 420, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Соедини фарш с луком и собери котлетную массу.',
          'Сформируй котлеты и обжарь их по 4-5 минут с каждой стороны.',
          'Подавай горячими.',
        ],
      ),
      recipeCanonicals: const {'фарш', 'лук'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Котлетному ужину нужен отдельный гарнир.'),
    );
    expect(
      result.violations,
      contains('Котлетный ужин должен явно подаваться вместе с гарниром.'),
    );
  });

  test('rejects zharkoe without staged browning and potato base', () {
    final result = validateChefDish(
      blueprint: _blueprint('zharkoe'),
      recipe: const Recipe(
        id: 'zharkoe-flat',
        title: 'Жаркое по-домашнему',
        timeMin: 24,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Говядина', amount: 450, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Подготовь говядину, лук и морковь.',
          'Влей воду и туши всё вместе 20 минут.',
          'Подавай горячим.',
        ],
      ),
      recipeCanonicals: const {'говядина', 'лук', 'морковь'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Жаркому нужна картофельная основа.'),
    );
    expect(
      result.violations,
      contains('Жаркому нужен отдельный этап обжарки мяса перед тушением.'),
    );
  });

  test('rejects zrazy without sealed filling structure', () {
    final result = validateChefDish(
      blueprint: _blueprint('zrazy'),
      recipe: const Recipe(
        id: 'zrazy-flat',
        title: 'Зразы по-домашнему',
        timeMin: 28,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Фарш', amount: 420, unit: Unit.g),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Гречка', amount: 180, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Отвари гречку на гарнир.',
          'Соедини фарш с луком и яйцом, затем сформируй плоские котлеты.',
          'Обжарь их по 4-5 минут с каждой стороны и подавай вместе с гарниром.',
        ],
      ),
      recipeCanonicals: const {'фарш', 'яйцо', 'гречка', 'лук'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Зразы должны закрывать начинку внутри мясной оболочки.'),
    );
  });

  test('rejects bitochki without gravy finish', () {
    final result = validateChefDish(
      blueprint: _blueprint('bitochki'),
      recipe: const Recipe(
        id: 'bitochki-dry',
        title: 'Биточки с подливкой',
        timeMin: 24,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Фарш', amount: 420, unit: Unit.g),
          RecipeIngredient(name: 'Картофель', amount: 700, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Отвари картофель на гарнир.',
          'Сформируй круглые биточки и обжарь их по 3-4 минуты с каждой стороны.',
          'Подавай биточки вместе с гарниром.',
        ],
      ),
      recipeCanonicals: const {'фарш', 'картофель', 'лук'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Биточкам нужна мягкая подливка, которая спокойно собирается вокруг мясной части.',
      ),
    );
    expect(
      result.violations,
      contains(
          'Биточки должны дойти в мягкой подливке после короткой обжарки.'),
    );
  });

  test('rejects tefteli without rice and sauce structure', () {
    final result = validateChefDish(
      blueprint: _blueprint('tefteli'),
      recipe: const Recipe(
        id: 'tefteli-flat',
        title: 'Тефтели в соусе',
        timeMin: 24,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Фарш', amount: 420, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Соедини фарш с луком и морковью.',
          'Туши всё вместе 15 минут.',
          'Подавай горячим.',
        ],
      ),
      recipeCanonicals: const {'фарш', 'лук', 'морковь'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Тефтелям нужен рис для правильной структуры.'),
    );
    expect(
      result.violations,
      contains('Тефтелям нужен соус через томатную пасту или сметану.'),
    );
    expect(
      result.violations,
      contains('Тефтели должны формоваться отдельно, а не тушиться россыпью.'),
    );
  });

  test('rejects tefteli with watery ungathered sauce', () {
    final result = validateChefDish(
      blueprint: _blueprint('tefteli'),
      recipe: const Recipe(
        id: 'tefteli-watery',
        title: 'Тефтели в соусе',
        timeMin: 30,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Фарш', amount: 420, unit: Unit.g),
          RecipeIngredient(name: 'Рис', amount: 90, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 120, unit: Unit.g),
        ],
        steps: [
          'Соедини фарш с рисом и луком, затем сформируй небольшие тефтели влажными руками.',
          'Добавь сметану, уложи тефтели в соус и туши их под крышкой 18-22 минуты на слабом огне.',
          'Подавай горячими сразу.',
        ],
      ),
      recipeCanonicals: const {'фарш', 'рис', 'лук', 'сметана'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
          'Тефтелям нужен собранный соус, который мягко обволакивает их, а не остаётся водянистым.'),
    );
  });

  test('rejects goulash without paprika depth and browning', () {
    final result = validateChefDish(
      blueprint: _blueprint('goulash'),
      recipe: const Recipe(
        id: 'goulash-flat',
        title: 'Гуляш по-домашнему',
        timeMin: 28,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Говядина', amount: 480, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Нарежь говядину и лук.',
          'Влей воду и туши всё вместе 20 минут.',
          'Подавай горячим.',
        ],
      ),
      recipeCanonicals: const {'говядина', 'лук'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Гуляшу нужна паприка или томатная глубина.'),
    );
    expect(
      result.violations,
      contains('Гуляшу нужен отдельный этап обжарки мяса перед тушением.'),
    );
  });

  test('rejects goulash that drifts into white sauce', () {
    final result = validateChefDish(
      blueprint: _blueprint('goulash'),
      recipe: const Recipe(
        id: 'goulash-white-sauce',
        title: 'Гуляш по-домашнему',
        timeMin: 34,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Говядина', amount: 480, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Паприка', amount: 6, unit: Unit.g),
          RecipeIngredient(name: 'Сметана', amount: 120, unit: Unit.g),
        ],
        steps: [
          'Нарежь говядину кусочками, лук мягко прогрей 4-5 минут и обжарь мясо ещё 5-6 минут.',
          'Добавь паприку и сметану, затем туши гуляш под крышкой 25-30 минут в белом соусе.',
          'Подавай горячим.',
        ],
      ),
      recipeCanonicals: const {'говядина', 'лук', 'паприка', 'сметана'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Гуляш не должен уходить в белый сметанный соус.'),
    );
  });

  test('rejects stroganoff with tomato drift and harsh finish', () {
    final result = validateChefDish(
      blueprint: _blueprint('beef_stroganoff'),
      recipe: const Recipe(
        id: 'stroganoff-wrong',
        title: 'Бефстроганов',
        timeMin: 24,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Говядина', amount: 450, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 140, unit: Unit.g),
          RecipeIngredient(name: 'Томатная паста', amount: 35, unit: Unit.g),
        ],
        steps: [
          'Нарежь говядину полосками и лук.',
          'Обжарь всё вместе 10 минут.',
          'Добавь сметану и бурно кипяти соус ещё 10 минут.',
        ],
      ),
      recipeCanonicals: const {'говядина', 'лук', 'сметана', 'томатная паста'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
          'Бефстроганов должен быстро обжаривать мясо, а не долго тушить его с начала.'),
    );
    expect(
      result.violations,
      contains(
          'Бефстроганов должен аккуратно дойти в сметанном соусе без сильного кипения.'),
    );
    expect(
      result.violations,
      contains('Бефстроганов не должен уходить в томатный профиль гуляша.'),
    );
  });

  test('rejects stroganoff that braises like goulash', () {
    final result = validateChefDish(
      blueprint: _blueprint('beef_stroganoff'),
      recipe: const Recipe(
        id: 'stroganoff-braised',
        title: 'Бефстроганов',
        timeMin: 30,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Говядина', amount: 450, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 140, unit: Unit.g),
        ],
        steps: [
          'Нарежь говядину тонкими полосками и лук.',
          'Быстро обжарь мясо 3-4 минуты, добавь сметану и туши бефстроганов под крышкой 25-30 минут.',
          'Подавай горячим.',
        ],
      ),
      recipeCanonicals: const {'говядина', 'лук', 'сметана'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
          'Бефстроганов не должен уходить в долгую тушёную технику гуляша.'),
    );
  });

  test('rejects draniki without moisture control', () {
    final result = validateChefDish(
      blueprint: _blueprint('draniki'),
      recipe: const Recipe(
        id: 'draniki-wet',
        title: 'Драники',
        timeMin: 18,
        tags: ['quick'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Картофель', amount: 4, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Натри картофель, мелко нарежь лук и смешай всё в массу.',
          'Дай массе постоять 5-7 минут.',
          'Выложи на сковороду и жарь как густое тесто.',
        ],
      ),
      recipeCanonicals: const {'картофель', 'лук', 'яйцо'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Драникам нужно убрать лишнюю влагу из картофельной массы.'),
    );
    expect(
      result.violations,
      contains('Драники не должны идти по логике блинного теста.'),
    );
  });

  test('accepts valid draniki structure', () {
    final result = validateChefDish(
      blueprint: _blueprint('draniki'),
      recipe: const Recipe(
        id: 'draniki-valid',
        title: 'Драники',
        timeMin: 20,
        tags: ['quick'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Картофель', amount: 4, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Натри картофель, мелко нарежь лук и собери плотную картофельную массу без лишней влаги.',
          'Выкладывай небольшие порции на сковороду и обжарь драники по 3-4 минуты с каждой стороны.',
          'Дай драникам 1 минуту стабилизироваться после сковороды и подавай горячими.',
        ],
      ),
      recipeCanonicals: const {'картофель', 'лук', 'яйцо'},
    );

    expect(result.isValid, isTrue);
    expect(result.violations, isEmpty);
  });

  test('rejects perfect omelette browned on hard heat', () {
    final result = validateChefDish(
      blueprint: _blueprint('perfect_omelette'),
      recipe: const Recipe(
        id: 'perfect-omelette-browned',
        title: 'Омлет классический',
        timeMin: 8,
        tags: ['breakfast', 'minimal'],
        servingsBase: 1,
        ingredients: [
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
        ],
        steps: [
          'Сильно взбей яйца до пены.',
          'Жарь омлет на сильном огне до румяной корочки.',
          'Оставь на столе и подай позже.',
        ],
      ),
      recipeCanonicals: const {'яйцо'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Классическому омлету нужно мягко взбить яйца, не загоняя их в пену.',
      ),
    );
    expect(
      result.violations,
      contains(
          'Классический омлет не должен жариться на сильном огне до корочки.'),
    );
  });

  test('accepts proper perfect omelette technique', () {
    final result = validateChefDish(
      blueprint: _blueprint('perfect_omelette'),
      recipe: const Recipe(
        id: 'perfect-omelette-valid',
        title: 'Омлет классический',
        timeMin: 8,
        tags: ['breakfast', 'minimal'],
        servingsBase: 1,
        ingredients: [
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
        ],
        steps: [
          'Разбей яйца в миску и слегка взбей вилкой — не до пены.',
          'Растопи масло на сковороде: оно должно пениться, но не темнеть. Влей яичную смесь и веди лопаткой по дну мелкими движениями непрерывно.',
          'Когда середина еще немного влажная, сверни омлет рулетом и подавай сразу.',
        ],
      ),
      recipeCanonicals: const {'яйцо'},
    );

    expect(result.isValid, isTrue);
    expect(result.violations, isEmpty);
  });

  test('rejects aglio e olio without emulsion and gentle garlic', () {
    final result = validateChefDish(
      blueprint: _blueprint('aglio_e_olio'),
      recipe: const Recipe(
        id: 'aglio-flat',
        title: 'Паста с чесноком и маслом',
        timeMin: 12,
        tags: ['minimal', 'pasta'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Макароны', amount: 200, unit: Unit.g),
          RecipeIngredient(name: 'Чеснок', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Оливковое масло', amount: 25, unit: Unit.ml),
        ],
        steps: [
          'Отвари макароны и слей воду.',
          'Обжарь чеснок до коричневого цвета.',
          'Смешай пасту с маслом и подавай.',
        ],
      ),
      recipeCanonicals: const {'макароны', 'чеснок', 'оливковое масло'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Aglio e olio требует сохранить крахмальную воду от варки для эмульсии.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Чеснок для aglio e olio должен стать только золотистым, а не коричневым и горьким.',
      ),
    );
  });

  test('rejects potato puree blended with cold dairy', () {
    final result = validateChefDish(
      blueprint: _blueprint('potato_puree'),
      recipe: const Recipe(
        id: 'potato-puree-wrong',
        title: 'Картофельное пюре',
        timeMin: 18,
        tags: ['minimal'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Картофель', amount: 700, unit: Unit.g),
          RecipeIngredient(name: 'Молоко', amount: 120, unit: Unit.ml),
        ],
        steps: [
          'Залей картофель горячей водой и отвари до мягкости.',
          'Пробей картофель блендером с холодным молоком.',
          'Подавай.',
        ],
      ),
      recipeCanonicals: const {'картофель', 'молоко'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Картофельное пюре должно начинаться из холодной подсоленной воды.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Картофельное пюре не должно идти через блендер и клейкую текстуру.',
      ),
    );
  });

  test('accepts proper cucumber salad with sour cream handling', () {
    final result = validateChefDish(
      blueprint: _blueprint('cucumber_smetana'),
      recipe: const Recipe(
        id: 'cucumber-smetana-valid',
        title: 'Огурцы со сметаной',
        timeMin: 5,
        tags: ['minimal', 'salad'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Огурцы', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 120, unit: Unit.g),
          RecipeIngredient(name: 'Укроп', amount: 10, unit: Unit.g),
        ],
        steps: [
          'Нарежь огурцы, посоли и оставь на 5 минут — так они отдадут лишнюю воду.',
          'Слей лишнюю жидкость, добавь сметану и укроп, перемешай аккуратно.',
          'Дай постоять 1-2 минуты и подавай.',
        ],
      ),
      recipeCanonicals: const {'огурец', 'сметана', 'укроп'},
    );

    expect(result.isValid, isTrue);
    expect(result.violations, isEmpty);
  });

  test('rejects shakshuka that scrambles eggs into the sauce', () {
    final result = validateChefDish(
      blueprint: _blueprint('shakshuka_light'),
      recipe: const Recipe(
        id: 'shakshuka-scrambled',
        title: 'Шакшука',
        timeMin: 12,
        tags: ['minimal', 'one_pan'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Помидоры', amount: 4, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Паприка', amount: 4, unit: Unit.g),
        ],
        steps: [
          'Обжарь томаты с паприкой 2 минуты.',
          'Взбей яйца и перемешай яйца с соусом прямо на сковороде.',
          'Жарь до полной сухости и подавай.',
        ],
      ),
      recipeCanonicals: const {'помидор', 'яйцо', 'паприка'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Шакшука не должна превращаться в яичную болтунью в томатном соусе.',
      ),
    );
  });

  test('rejects egg skillet fried hard into crust', () {
    final result = validateChefDish(
      blueprint: _blueprint('egg_skillet'),
      recipe: const Recipe(
        id: 'egg-skillet-hard',
        title: 'Яичная сковорода',
        timeMin: 10,
        tags: ['breakfast', 'one_pan'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Помидоры', amount: 2, unit: Unit.pcs),
        ],
        steps: [
          'Разбей яйца на сковороду.',
          'Жарь на сильном огне до румяной корочки.',
          'Подавай позже.',
        ],
      ),
      recipeCanonicals: const {'яйцо', 'помидор'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Яичная сковорода не должна зажариваться на сильном огне до грубой корочки.',
      ),
    );
  });

  test('rejects potato skillet without one-layer crust logic', () {
    final result = validateChefDish(
      blueprint: _blueprint('potato_skillet'),
      recipe: const Recipe(
        id: 'potato-skillet-flat',
        title: 'Румяный картофель',
        timeMin: 18,
        tags: ['one_pan'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Картофель', amount: 600, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Нарежь картофель и лук.',
          'Сложи всё в сковороду и мешай до мягкости.',
          'Подавай.',
        ],
      ),
      recipeCanonicals: const {'картофель', 'лук'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Картофельной сковороде нужен один слой и работа на корочку, а не хаотичное тушение.',
      ),
    );
  });

  test('accepts generic pasta pan with reserved cooking water', () {
    final result = validateChefDish(
      blueprint: _blueprint('pasta_pan'),
      recipe: const Recipe(
        id: 'pasta-pan-valid',
        title: 'Макароны на скорую руку',
        timeMin: 14,
        tags: ['pasta'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Макароны', amount: 220, unit: Unit.g),
          RecipeIngredient(name: 'Чеснок', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Помидоры', amount: 2, unit: Unit.pcs),
        ],
        steps: [
          'Отвари макароны 8-10 минут до al dente и сохрани несколько ложек воды от варки.',
          'Соедини пасту с чесноком и помидорами на сковороде, добавь немного воды от варки и быстро прогрей всё 2-3 минуты, чтобы соки покрыли пасту.',
          'Оставь на минуту после выключения огня и подавай.',
        ],
      ),
      recipeCanonicals: const {'макароны', 'чеснок', 'помидор'},
    );

    expect(result.isValid, isTrue);
    expect(result.violations, isEmpty);
  });

  test('rejects generic bake that has no moisture protection', () {
    final result = validateChefDish(
      blueprint: _blueprint('bake'),
      recipe: const Recipe(
        id: 'bake-dry',
        title: 'Запеканка',
        timeMin: 35,
        tags: ['bake'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Курица', amount: 300, unit: Unit.g),
          RecipeIngredient(name: 'Картофель', amount: 400, unit: Unit.g),
        ],
        steps: [
          'Сложи курицу и картофель в форму.',
          'Запекай до готовности.',
          'Сразу режь и подавай.',
        ],
      ),
      recipeCanonicals: const {'курица', 'картофель'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Запеканию нужна защита от сухости через связку, покрытие или контроль влаги.',
      ),
    );
  });

  test('rejects cabbage egg pie without rested dough', () {
    final result = validateChefDish(
      blueprint: _blueprint('cabbage_egg_pie'),
      recipe: const Recipe(
        id: 'pie-rushed-dough',
        title: 'Пирог домашний: Капуста, Яйца',
        timeMin: 48,
        tags: ['oven', 'pie'],
        servingsBase: 4,
        ingredients: [
          RecipeIngredient(name: 'Мука', amount: 260, unit: Unit.g),
          RecipeIngredient(name: 'Капуста', amount: 450, unit: Unit.g),
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сливочное масло', amount: 70, unit: Unit.g),
        ],
        steps: [
          'Подготовь начинку: тонко нашинкуй капусту и мелко нарежь лук. Спокойно прогрей её на сливочном масле 8-10 минут, пока лишняя влага не уйдёт; отдельно отвари яйца 8-9 минут, остуди, мелко поруби и вмешай в полностью остывшую начинку, доведя её через соль и перец.',
          'Подготовь тесто: просей муку, быстро вработай сливочное масло до влажной крошки и часть яйца, чтобы собрать мягкое тесто.',
          'Раздели тесто на две части, раскатай нижний пласт и выложи его в форму. Сверху разложи холодную начинку, накрой вторым пластом, защипни края, запечатай шов и сделай 2-3 отверстия для выхода пара.',
          'Выпекай пирог в духовке 35-40 минут при 180-190°C до ровной золотистой корочки. Дай ему отдохнуть 12-15 минут, затем нарежь и подавай тёплым.',
        ],
      ),
      recipeCanonicals: const {
        'мука',
        'капуста',
        'яйцо',
        'лук',
        'масло сливочное',
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Тесту для закрытого пирога нужен отдых перед раскаткой.'),
    );
  });

  test('rejects cabbage egg pie with raw filling and no steam vent', () {
    final result = validateChefDish(
      blueprint: _blueprint('cabbage_egg_pie'),
      recipe: const Recipe(
        id: 'pie-raw-filling',
        title: 'Пирог домашний: Капуста, Яйца',
        timeMin: 44,
        tags: ['oven', 'pie'],
        servingsBase: 4,
        ingredients: [
          RecipeIngredient(name: 'Мука', amount: 260, unit: Unit.g),
          RecipeIngredient(name: 'Капуста', amount: 450, unit: Unit.g),
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 120, unit: Unit.g),
        ],
        steps: [
          'Подготовь тесто: просей муку, добавь часть яйца и сметану и быстро собери мягкое тесто. Не вымешивай долго; заверни тесто и дай ему отдохнуть 20 минут в холоде.',
          'Смешай сырую капусту с рублеными яйцами и сразу разложи начинку на тесто.',
          'Раздели тесто на две части, раскатай нижний пласт и выложи его в форму. Сверху разложи начинку, накрой вторым пластом и защипни края.',
          'Выпекай пирог в духовке 35-40 минут при 180-190°C до корочки. Дай ему отдохнуть 12-15 минут, затем нарежь и подавай.',
        ],
      ),
      recipeCanonicals: const {'мука', 'капуста', 'яйцо', 'сметана'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Начинку для пирога нужно отдельно приготовить и убрать лишнюю влагу.',
      ),
    );
    expect(
      result.violations,
      contains(
        'У закрытого пирога должен быть выход пара, иначе верх намокнет и лопнет.',
      ),
    );
  });

  test('accepts valid cabbage egg pie with closed-pie technique', () {
    final result = validateChefDish(
      blueprint: _blueprint('cabbage_egg_pie'),
      recipe: const Recipe(
        id: 'pie-valid',
        title: 'Пирог домашний: Капуста, Яйца',
        timeMin: 72,
        tags: ['oven', 'pie'],
        servingsBase: 4,
        ingredients: [
          RecipeIngredient(name: 'Мука', amount: 260, unit: Unit.g),
          RecipeIngredient(name: 'Капуста', amount: 450, unit: Unit.g),
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сливочное масло', amount: 70, unit: Unit.g),
        ],
        steps: [
          'Подготовь начинку: тонко нашинкуй капусту и мелко нарежь лук. Спокойно прогрей её на сливочном масле 8-10 минут, пока лишняя влага не уйдёт; отдельно отвари яйца 8-9 минут, остуди, мелко поруби и вмешай в полностью остывшую начинку, доведя её через соль и перец.',
          'Подготовь тесто: просей муку, быстро вработай сливочное масло до влажной крошки и часть яйца, чтобы собрать мягкое тесто. Не вымешивай долго; заверни тесто и дай ему отдохнуть 20 минут в холоде.',
          'Раздели тесто на две части, раскатай нижний пласт и выложи его в форму или на противень. Сверху разложи холодную начинку, накрой вторым пластом, защипни края, запечатай шов, сделай 2-3 отверстия для выхода пара и, если часть яйца осталась, смажь верх.',
          'Выпекай пирог в духовке 35-40 минут при 180-190°C до ровной золотистой корочки. Дай ему отдохнуть 12-15 минут, затем нарежь и подавай тёплым.',
        ],
      ),
      recipeCanonicals: const {
        'мука',
        'капуста',
        'яйцо',
        'лук',
        'масло сливочное',
      },
    );

    expect(result.isValid, isTrue);
    expect(result.violations, isEmpty);
  });

  test('rejects generic cutlets without gentle finish', () {
    final result = validateChefDish(
      blueprint: _blueprint('kotlet_dinner'),
      recipe: const Recipe(
        id: 'cutlets-flat',
        title: 'Домашние котлеты',
        timeMin: 24,
        tags: ['cutlets'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Фарш', amount: 500, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Картофель', amount: 5, unit: Unit.pcs),
        ],
        steps: [
          'Подготовь картофель как простой гарнир.',
          'Смешай фарш с луком.',
          'Сформируй котлеты и жарь 4-5 минут с каждой стороны.',
          'Подавай вместе с гарниром.',
        ],
      ),
      recipeCanonicals: const {'фарш', 'лук', 'картофель'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Котлетам нужна мягкая доводка и короткий отдых перед подачей.',
      ),
    );
  });

  test('rejects generic stew without covered slow finish', () {
    final result = validateChefDish(
      blueprint: _blueprint('stew'),
      recipe: const Recipe(
        id: 'stew-flat',
        title: 'Домашнее рагу',
        timeMin: 28,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Говядина', amount: 400, unit: Unit.g),
          RecipeIngredient(name: 'Картофель', amount: 400, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Сложи всё сразу в кастрюлю.',
          'Туши до готовности.',
          'Подавай.',
        ],
      ),
      recipeCanonicals: const {'говядина', 'картофель', 'лук'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Рагу должно начинаться с базы и самых плотных продуктов, а не сваливаться в одну фазу.',
      ),
    );
  });
}

ChefBlueprint _blueprint(String id) {
  return chefBlueprints.firstWhere((blueprint) => blueprint.id == id);
}
