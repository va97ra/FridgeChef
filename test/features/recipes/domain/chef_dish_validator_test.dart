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

  test('accepts mushroom soup with sauteed mushrooms and soft finish', () {
    final result = validateChefDish(
      blueprint: _blueprint('mushroom_soup'),
      recipe: const Recipe(
        id: 'mushroom-soup-valid',
        title: 'Грибной суп домашний',
        timeMin: 32,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Грибы', amount: 320, unit: Unit.g),
          RecipeIngredient(name: 'Картофель', amount: 4, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 60, unit: Unit.g),
          RecipeIngredient(name: 'Укроп', amount: 12, unit: Unit.g),
        ],
        steps: [
          'Нарежь грибы, картофель, лук и морковь, сначала мягко прогрей лук и морковь 4-5 минут, затем добавь грибы и выпарь их 4-6 минут.',
          'Влей воду, добавь картофель и вари грибной суп 16-18 минут на спокойном огне.',
          'Сними с огня, доведи вкус и подай со сметаной и укропом.',
        ],
      ),
      recipeCanonicals: const {
        'грибы',
        'картофель',
        'лук',
        'морковь',
        'сметана',
        'укроп',
      },
    );

    expect(result.isValid, isTrue, reason: result.violations.join('\n'));
  });

  test('rejects mushroom soup that boils mushrooms from raw in water', () {
    final result = validateChefDish(
      blueprint: _blueprint('mushroom_soup'),
      recipe: const Recipe(
        id: 'mushroom-soup-flat',
        title: 'Грибной суп домашний',
        timeMin: 24,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Грибы', amount: 320, unit: Unit.g),
          RecipeIngredient(name: 'Картофель', amount: 4, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 60, unit: Unit.g),
        ],
        steps: [
          'Подготовь грибы, картофель и лук.',
          'Влей воду, добавь грибы, картофель и лук сразу и вари суп 18 минут.',
          'В конце добавь сметану и подавай.',
        ],
      ),
      recipeCanonicals: const {'грибы', 'картофель', 'лук', 'сметана'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Грибной суп должен сначала прогреть грибы с ароматической базой, а не варить их сырыми в воде.',
      ),
    );
  });

  test('accepts pea smoked soup with prepared peas and smoked base', () {
    final result = validateChefDish(
      blueprint: _blueprint('pea_smoked_soup'),
      recipe: const Recipe(
        id: 'pea-smoked-valid',
        title: 'Гороховый суп с копченостями',
        timeMin: 48,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Горох', amount: 260, unit: Unit.g),
          RecipeIngredient(
            name: 'Копченая колбаса',
            amount: 220,
            unit: Unit.g,
          ),
          RecipeIngredient(name: 'Картофель', amount: 4, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Укроп', amount: 12, unit: Unit.g),
        ],
        steps: [
          'Промой горох, картофель пока держи отдельно, сначала мягко прогрей лук и морковь 4-5 минут и затем добавь копченую колбасу еще на 1-2 минуты.',
          'Влей воду, добавь горох и вари гороховый суп 35-45 минут на спокойном огне, а картофель положи на последние 12-15 минут.',
          'Сними с огня, доведи вкус и подай с укропом.',
        ],
      ),
      recipeCanonicals: const {
        'горох',
        'колбаса',
        'картофель',
        'лук',
        'морковь',
        'укроп',
      },
    );

    expect(result.isValid, isTrue, reason: result.violations.join('\n'));
  });

  test('rejects pea smoked soup without smoked meat cue', () {
    final result = validateChefDish(
      blueprint: _blueprint('pea_smoked_soup'),
      recipe: const Recipe(
        id: 'pea-smoked-no-smoke',
        title: 'Гороховый суп домашний',
        timeMin: 46,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Горох', amount: 260, unit: Unit.g),
          RecipeIngredient(name: 'Колбаса', amount: 220, unit: Unit.g),
          RecipeIngredient(name: 'Картофель', amount: 4, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Промой горох, картофель пока держи отдельно, сначала мягко прогрей лук и морковь 4-5 минут и затем добавь колбасу еще на 1-2 минуты.',
          'Влей воду, добавь горох и вари суп 35-45 минут на спокойном огне, а картофель положи на последние 12-15 минут.',
          'Сними с огня и подавай.',
        ],
      ),
      recipeCanonicals: const {
        'горох',
        'колбаса',
        'картофель',
        'лук',
        'морковь'
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Гороховый суп должен опираться на явно копчёную мясную основу, а не на абстрактную колбасу.',
      ),
    );
  });

  test('rejects pea smoked soup with rushed pea simmer', () {
    final result = validateChefDish(
      blueprint: _blueprint('pea_smoked_soup'),
      recipe: const Recipe(
        id: 'pea-smoked-rushed',
        title: 'Гороховый суп с копченостями',
        timeMin: 24,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Горох', amount: 260, unit: Unit.g),
          RecipeIngredient(
            name: 'Копченая колбаса',
            amount: 220,
            unit: Unit.g,
          ),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Подготовь горох, лук, морковь и копченую колбасу.',
          'Влей воду, добавь все сразу и вари суп 18 минут.',
          'Подавай.',
        ],
      ),
      recipeCanonicals: const {'горох', 'колбаса', 'лук', 'морковь'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Гороховый суп должен томить горох 30-45 минут до мягкости.',
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

  test('accepts classic golubtsy with wrapped leaves and sauce braise', () {
    final result = validateChefDish(
      blueprint: _blueprint('classic_golubtsy'),
      recipe: const Recipe(
        id: 'classic-golubtsy',
        title: 'Голубцы классические',
        timeMin: 52,
        tags: ['stew'],
        servingsBase: 4,
        ingredients: [
          RecipeIngredient(name: 'Фарш', amount: 500, unit: Unit.g),
          RecipeIngredient(name: 'Рис', amount: 220, unit: Unit.g),
          RecipeIngredient(name: 'Капуста', amount: 1200, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Томатная паста', amount: 45, unit: Unit.g),
          RecipeIngredient(name: 'Сметана', amount: 120, unit: Unit.g),
        ],
        steps: [
          'Подготовь капусту: сними крупные листья, опусти их в кипящую воду на 2-3 минуты и обсуши, а лук с морковью мягко прогрей 4-5 минут.',
          'Соедини фарш с рисом и частью овощной базы в плотную начинку, уложи её на листья капусты, плотно заверни голубцы и уложи их швом вниз.',
          'Добавь томатную пасту и сметану, накрой и туши голубцы 30-35 минут на слабом огне, затем дай им постоять 3-4 минуты.',
        ],
      ),
      recipeCanonicals: const {
        'фарш',
        'рис',
        'капуста',
        'лук',
        'морковь',
        'томатная паста',
        'сметана',
      },
    );

    expect(result.isValid, isTrue);
    expect(result.violations, isEmpty);
  });

  test('rejects classic golubtsy without wrapped leaf technique', () {
    final result = validateChefDish(
      blueprint: _blueprint('classic_golubtsy'),
      recipe: const Recipe(
        id: 'classic-golubtsy-flat',
        title: 'Голубцы классические',
        timeMin: 36,
        tags: ['stew'],
        servingsBase: 4,
        ingredients: [
          RecipeIngredient(name: 'Фарш', amount: 500, unit: Unit.g),
          RecipeIngredient(name: 'Рис', amount: 220, unit: Unit.g),
          RecipeIngredient(name: 'Капуста', amount: 900, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Томатная паста', amount: 45, unit: Unit.g),
        ],
        steps: [
          'Соедини фарш, рис и капусту в общую массу.',
          'Добавь томатную пасту и туши всё вместе 20 минут.',
          'Подавай горячим.',
        ],
      ),
      recipeCanonicals: const {
        'фарш',
        'рис',
        'капуста',
        'лук',
        'томатная паста',
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Классическим голубцам нужно подготовить и смягчить капустные листья.',
      ),
    );
    expect(
      result.violations,
      contains('Классические голубцы нужно заворачивать в капустные листья.'),
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

  test('rejects liver fritters without blended liver batter', () {
    final result = validateChefDish(
      blueprint: _blueprint('liver_fritters'),
      recipe: const Recipe(
        id: 'liver-fritters-chopped',
        title: 'Печеночные оладьи',
        timeMin: 20,
        tags: ['quick'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Печень', amount: 380, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Мука', amount: 70, unit: Unit.g),
        ],
        steps: [
          'Нарежь печень кусочками, смешай с луком, яйцами и мукой.',
          'Сформируй котлеты руками и обжарь на сковороде.',
          'Подавай горячими.',
        ],
      ),
      recipeCanonicals: const {'печень', 'лук', 'яйцо', 'мука'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Печеночным оладьям нужна гладкая печеночная масса, а не рубленые куски печени.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Печеночные оладьи не должны формоваться как сырники или котлеты.',
      ),
    );
  });

  test('rejects liver fritters that drift into sweet baked batter', () {
    final result = validateChefDish(
      blueprint: _blueprint('liver_fritters'),
      recipe: const Recipe(
        id: 'liver-fritters-sweet',
        title: 'Печеночные оладьи',
        timeMin: 26,
        tags: ['quick'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Печень', amount: 380, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Мука', amount: 70, unit: Unit.g),
          RecipeIngredient(name: 'Сахар', amount: 20, unit: Unit.g),
        ],
        steps: [
          'Пробей печень с луком, яйцами, мукой и сахаром в массу.',
          'Разлей массу по форме и запекай 20 минут в духовке.',
          'Подавай тёплыми.',
        ],
      ),
      recipeCanonicals: const {'печень', 'лук', 'яйцо', 'мука', 'сахар'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Печеночные оладьи не должны уходить в сладкий профиль.'),
    );
    expect(
      result.violations,
      contains('Печеночные оладьи не должны уходить в запекание.'),
    );
  });

  test('accepts valid liver fritters structure', () {
    final result = validateChefDish(
      blueprint: _blueprint('liver_fritters'),
      recipe: const Recipe(
        id: 'liver-fritters-valid',
        title: 'Печеночные оладьи',
        timeMin: 22,
        tags: ['quick'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Печень', amount: 380, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Мука', amount: 70, unit: Unit.g),
          RecipeIngredient(name: 'Сметана', amount: 90, unit: Unit.g),
        ],
        steps: [
          'Промой печень, крупно нарежь лук и пробей всё вместе в гладкую печеночную массу.',
          'Добавь яйца и муку, размешай густую печеночную массу и дай ей постоять 5-7 минут.',
          'Выкладывай массу ложкой небольшими порциями на сковороду и жарь печеночные оладьи по 2-3 минуты с каждой стороны.',
          'Дай оладьям 1 минуту собраться и подавай со сметаной.',
        ],
      ),
      recipeCanonicals: const {'печень', 'лук', 'яйцо', 'мука', 'сметана'},
    );

    expect(result.isValid, isTrue, reason: result.violations.join('\n'));
    expect(result.violations, isEmpty);
  });

  test('rejects liver cake without layered chilled assembly', () {
    final result = validateChefDish(
      blueprint: _blueprint('liver_cake'),
      recipe: const Recipe(
        id: 'liver-cake-flat',
        title: 'Печеночный торт',
        timeMin: 30,
        tags: ['cold'],
        servingsBase: 6,
        ingredients: [
          RecipeIngredient(name: 'Печень', amount: 420, unit: Unit.g),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Мука', amount: 90, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Майонез', amount: 120, unit: Unit.g),
        ],
        steps: [
          'Пробей печень с яйцами и мукой в гладкое печеночное тесто.',
          'Мелко нарежь лук и морковь, быстро обжарь их и смешай всё вместе на сковороде.',
          'Сразу подавай горячим.',
        ],
      ),
      recipeCanonicals: const {
        'печень',
        'яйцо',
        'мука',
        'лук',
        'морковь',
        'майонез',
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Печеночный торт должен собираться слоями, а не подаваться россыпью.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Печеночный торт должен настояться в холоде перед подачей.',
      ),
    );
  });

  test('rejects liver cake baked as one hot mass', () {
    final result = validateChefDish(
      blueprint: _blueprint('liver_cake'),
      recipe: const Recipe(
        id: 'liver-cake-baked',
        title: 'Печеночный торт',
        timeMin: 55,
        tags: ['cold'],
        servingsBase: 6,
        ingredients: [
          RecipeIngredient(name: 'Печень', amount: 420, unit: Unit.g),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Мука', amount: 90, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 140, unit: Unit.g),
        ],
        steps: [
          'Пробей печень с яйцами и мукой в гладкое печеночное тесто.',
          'Мелко нарежь лук и морковь, вмешай сметану, вылей всё в форму и запекай в духовке 30 минут.',
          'Сразу подавай горячим.',
        ],
      ),
      recipeCanonicals: const {
        'печень',
        'яйцо',
        'мука',
        'лук',
        'морковь',
        'сметана',
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Печеночный торт не должен превращаться в одну запеченную массу.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Печеночный торт не должен подаваться сразу горячим со сковороды.',
      ),
    );
  });

  test('accepts valid liver cake structure', () {
    final result = validateChefDish(
      blueprint: _blueprint('liver_cake'),
      recipe: const Recipe(
        id: 'liver-cake-valid',
        title: 'Печеночный торт',
        timeMin: 48,
        tags: ['cold'],
        servingsBase: 6,
        ingredients: [
          RecipeIngredient(name: 'Печень', amount: 420, unit: Unit.g),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Мука', amount: 90, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Майонез', amount: 120, unit: Unit.g),
        ],
        steps: [
          'Промой печень, зачисти жилки и пробей её с яйцами и мукой в гладкое печеночное тесто.',
          'Мелко нарежь лук и морковь, спокойно обжарь овощную прослойку. На слегка смазанной сковороде жарь тонкие печеночные коржи по 1-2 минуты с каждой стороны и каждый корж отдельно остуди.',
          'Собери печеночный торт слоями: каждый корж, тонкий слой майонеза и часть овощной прослойки.',
          'Накрой и убери в холодильник на 2-3 часа, затем подавай холодным.',
        ],
      ),
      recipeCanonicals: const {
        'печень',
        'яйцо',
        'мука',
        'лук',
        'морковь',
        'майонез',
      },
    );

    expect(result.isValid, isTrue, reason: result.violations.join('\n'));
    expect(result.violations, isEmpty);
  });

  test('rejects charlotte without airy batter and apple layering', () {
    final result = validateChefDish(
      blueprint: _blueprint('charlotte'),
      recipe: const Recipe(
        id: 'charlotte-flat',
        title: 'Шарлотка',
        timeMin: 28,
        tags: ['bake'],
        servingsBase: 4,
        ingredients: [
          RecipeIngredient(name: 'Яблоко', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Мука', amount: 180, unit: Unit.g),
          RecipeIngredient(name: 'Сахар', amount: 100, unit: Unit.g),
        ],
        steps: [
          'Смешай яблоки, яйца, сахар и муку в густую массу.',
          'Переложи всё в форму и запекай 25 минут.',
          'Сразу нарежь и подавай.',
        ],
      ),
      recipeCanonicals: const {'яблоко', 'яйцо', 'мука', 'сахар'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Шарлотке нужен пышный яично-сахарный бисквит, а не плотная смешанная масса.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Шарлотке нужно уложить яблоки в форму и залить их бисквитным тестом.',
      ),
    );
  });

  test('rejects charlotte drifting into savory skillet bake', () {
    final result = validateChefDish(
      blueprint: _blueprint('charlotte'),
      recipe: const Recipe(
        id: 'charlotte-savory',
        title: 'Шарлотка',
        timeMin: 20,
        tags: ['bake'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Яблоко', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Мука', amount: 160, unit: Unit.g),
          RecipeIngredient(name: 'Сахар', amount: 80, unit: Unit.g),
          RecipeIngredient(name: 'Сыр', amount: 90, unit: Unit.g),
        ],
        steps: [
          'Смешай яблоки, яйца, сахар, муку и сыр.',
          'Обжарь массу на сковороде 8 минут с двух сторон.',
          'Подавай горячей прямо со сковороды.',
        ],
      ),
      recipeCanonicals: const {'яблоко', 'яйцо', 'мука', 'сахар', 'сыр'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Шарлотка не должна уходить в savory-запеканку или несладкий пирог.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Шарлотка не должна жариться на сковороде или превращаться в раскатной пирог.',
      ),
    );
  });

  test('accepts valid charlotte structure', () {
    final result = validateChefDish(
      blueprint: _blueprint('charlotte'),
      recipe: const Recipe(
        id: 'charlotte-valid',
        title: 'Шарлотка',
        timeMin: 46,
        tags: ['bake', 'sweet'],
        servingsBase: 4,
        ingredients: [
          RecipeIngredient(name: 'Яблоко', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 4, unit: Unit.pcs),
          RecipeIngredient(name: 'Мука', amount: 180, unit: Unit.g),
          RecipeIngredient(name: 'Сахар', amount: 120, unit: Unit.g),
          RecipeIngredient(
            name: 'Сливочное масло',
            amount: 25,
            unit: Unit.g,
          ),
          RecipeIngredient(name: 'Корица', amount: 3, unit: Unit.g),
        ],
        steps: [
          'Смажь форму сливочным маслом, нарежь яблоки тонкими дольками и разложи яблоки в форме ровным слоем.',
          'Взбей яйца с сахаром 4-5 минут в светлую пышную массу, затем аккуратно вмешай муку лопаткой.',
          'Вылей тесто на яблоки и запекай шарлотку 30-35 минут при 180°C до золотистой корочки.',
          'Дай шарлотке постоять 10 минут перед нарезкой и подавай тёплой с корицей.',
        ],
      ),
      recipeCanonicals: const {
        'яблоко',
        'яйцо',
        'мука',
        'сахар',
        'масло сливочное',
        'корица',
      },
    );

    expect(result.isValid, isTrue, reason: result.violations.join('\n'));
    expect(result.violations, isEmpty);
  });

  test('rejects sauerkraut preserve without fermentation structure', () {
    final result = validateChefDish(
      blueprint: _blueprint('sauerkraut_preserve'),
      recipe: const Recipe(
        id: 'sauerkraut-flat',
        title: 'Квашеная капуста',
        timeMin: 12,
        tags: ['preserve'],
        servingsBase: 4,
        ingredients: [
          RecipeIngredient(name: 'Капуста', amount: 700, unit: Unit.g),
          RecipeIngredient(name: 'Соль', amount: 18, unit: Unit.g),
          RecipeIngredient(name: 'Майонез', amount: 80, unit: Unit.g),
        ],
        steps: [
          'Нашинкуй капусту.',
          'Сразу заправь капусту майонезом и уксусом.',
          'Подавай сразу.',
        ],
      ),
      recipeCanonicals: const {'капуста', 'соль', 'майонез'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Квашеную капусту нужно плотно утрамбовать и держать под соком.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Квашеная капуста не должна уходить в салат с заправкой или горячий гарнир.',
      ),
    );
  });

  test('accepts valid sauerkraut preserve structure', () {
    final result = validateChefDish(
      blueprint: _blueprint('sauerkraut_preserve'),
      recipe: const Recipe(
        id: 'sauerkraut-valid',
        title: 'Квашеная капуста',
        timeMin: 4320,
        tags: ['preserve'],
        servingsBase: 6,
        ingredients: [
          RecipeIngredient(name: 'Капуста', amount: 800, unit: Unit.g),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Соль', amount: 18, unit: Unit.g),
        ],
        steps: [
          'Тонко нашинкуй капусту и натри морковь на крупной тёрке. Добавь соль и перетри капусту руками 4-5 минут, пока она не даст сок.',
          'Плотно уложи капусту в банку, утрамбуй и прижми так, чтобы капуста оставалась под соком.',
          'Оставь капусту при комнатной температуре на 2-3 дня и 2-3 раза в день прокалывай её до дна, выпуская газ.',
          'Убери квашеную капусту в холод на 6-8 часов и подавай холодной.',
        ],
      ),
      recipeCanonicals: const {'капуста', 'морковь', 'соль'},
    );

    expect(result.isValid, isTrue, reason: result.violations.join('\n'));
    expect(result.violations, isEmpty);
  });

  test('rejects lightly salted cucumbers drifting into dressed salad', () {
    final result = validateChefDish(
      blueprint: _blueprint('lightly_salted_cucumbers'),
      recipe: const Recipe(
        id: 'light-cucumber-flat',
        title: 'Малосольные огурцы',
        timeMin: 10,
        tags: ['preserve'],
        servingsBase: 4,
        ingredients: [
          RecipeIngredient(name: 'Огурцы', amount: 5, unit: Unit.pcs),
          RecipeIngredient(name: 'Укроп', amount: 20, unit: Unit.g),
          RecipeIngredient(name: 'Чеснок', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Соль', amount: 18, unit: Unit.g),
          RecipeIngredient(name: 'Сметана', amount: 80, unit: Unit.g),
        ],
        steps: [
          'Нарежь огурцы кружками.',
          'Заправь сметаной и сразу подавай.',
        ],
      ),
      recipeCanonicals: const {'огурец', 'укроп', 'чеснок', 'соль', 'сметана'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Малосольные огурцы должны солиться в явном рассоле, который покрывает огурцы.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Малосольные огурцы не должны превращаться в обычный салат или горячую закуску.',
      ),
    );
  });

  test('accepts valid lightly salted cucumbers structure', () {
    final result = validateChefDish(
      blueprint: _blueprint('lightly_salted_cucumbers'),
      recipe: const Recipe(
        id: 'light-cucumber-valid',
        title: 'Малосольные огурцы',
        timeMin: 720,
        tags: ['preserve'],
        servingsBase: 4,
        ingredients: [
          RecipeIngredient(name: 'Огурцы', amount: 6, unit: Unit.pcs),
          RecipeIngredient(name: 'Укроп', amount: 25, unit: Unit.g),
          RecipeIngredient(name: 'Чеснок', amount: 4, unit: Unit.pcs),
          RecipeIngredient(name: 'Соль', amount: 20, unit: Unit.g),
        ],
        steps: [
          'Срежь кончики у огурцов и уложи огурцы в контейнер слоями с укропом и чесноком.',
          'Раствори соль в холодной воде и залей огурцы рассолом так, чтобы они были полностью покрыты.',
          'Оставь огурцы при комнатной температуре на 8-12 часов или на ночь.',
          'После этого убери малосольные огурцы в холод минимум на 2-3 часа и подавай охлаждёнными.',
        ],
      ),
      recipeCanonicals: const {'огурец', 'укроп', 'чеснок', 'соль'},
    );

    expect(result.isValid, isTrue, reason: result.violations.join('\n'));
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

  test('rejects shawarma built from boiled chicken without sealed finish', () {
    final result = validateChefDish(
      blueprint: _blueprint('chicken_shawarma_wrap'),
      recipe: const Recipe(
        id: 'shawarma-flat',
        title: 'Шаурма домашняя',
        timeMin: 18,
        tags: ['street_food', 'wrap'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Курица', amount: 280, unit: Unit.g),
          RecipeIngredient(name: 'Лаваш', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Огурцы', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Помидоры', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 90, unit: Unit.g),
          RecipeIngredient(name: 'Чеснок', amount: 2, unit: Unit.pcs),
        ],
        steps: [
          'Отвари курицу до готовности и нарежь кусочками.',
          'Смешай сметану с чесноком.',
          'Выложи курицу, огурцы и помидоры на холодный лаваш и сверни рулетом.',
        ],
      ),
      recipeCanonicals: const {
        'курица',
        'лаваш',
        'огурец',
        'помидор',
        'сметана',
        'чеснок',
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Шаурма не должна строиться на варёной курице без жареной корочки.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Шаурме нужна финишная обжарка швом вниз, чтобы запечатать рулет и дать хруст.',
      ),
    );
  });

  test('rejects shawarma without cold sauce and enough fresh structure', () {
    final result = validateChefDish(
      blueprint: _blueprint('chicken_shawarma_wrap'),
      recipe: const Recipe(
        id: 'shawarma-dry',
        title: 'Шаурма домашняя',
        timeMin: 16,
        tags: ['street_food', 'wrap'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Курица', amount: 280, unit: Unit.g),
          RecipeIngredient(name: 'Лаваш', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Капуста', amount: 160, unit: Unit.g),
        ],
        steps: [
          'Быстро обжарь курицу на горячей сковороде до корочки.',
          'Нашинкуй капусту и заверни всё в лаваш.',
          'Сразу ешь.',
        ],
      ),
      recipeCanonicals: const {'курица', 'лаваш', 'капуста'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Шаурме нужен отдельный холодный соус на сметане или йогурте.',
      ),
    );
    expect(
      result.violations,
      contains(
        'Шаурме нужна свежая часть минимум из двух компонентов, чтобы вкус не был плоским и сухим.',
      ),
    );
  });

  test('accepts shawarma with seared chicken and sealed wrap technique', () {
    final result = validateChefDish(
      blueprint: _blueprint('chicken_shawarma_wrap'),
      recipe: const Recipe(
        id: 'shawarma-valid',
        title: 'Шаурма домашняя',
        timeMin: 24,
        tags: ['street_food', 'wrap'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Курица', amount: 280, unit: Unit.g),
          RecipeIngredient(name: 'Лаваш', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Капуста', amount: 160, unit: Unit.g),
          RecipeIngredient(name: 'Огурцы', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Помидоры', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 90, unit: Unit.g),
          RecipeIngredient(name: 'Чеснок', amount: 2, unit: Unit.pcs),
        ],
        steps: [
          'Нарежь курицу тонкими полосками, приправь паприкой, солью и перцем. Прогрей масло на очень горячей сковороде и быстро обжарь курицу 6-7 минут до уверенной румяной корочки, затем дай мясу 2 минуты отдохнуть.',
          'Тонко нашинкуй капусту, огурцы и помидоры и держи свежую часть отдельно. Если помидоры дают лишнюю влагу, промокни сок. Смешай сметану с чесноком в густой холодный соус. Коротко прогрей лаваш 10-15 секунд.',
          'Разложи лаваш, смажь середину соусом, сверху собери курицу и свежую часть, оставив сухой край 2-3 см для шва. Подверни боковые края и плотно сверни шаурму конвертом.',
          'Верни шаурму на сковороду швом вниз и обжарь 1-2 минуты с каждой стороны, чтобы рулет запечатался. Подавай сразу.',
        ],
      ),
      recipeCanonicals: const {
        'курица',
        'лаваш',
        'капуста',
        'огурец',
        'помидор',
        'сметана',
        'чеснок',
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

  test('accepts green shchi with late sorrel finish', () {
    final result = validateChefDish(
      blueprint: _blueprint('green_shchi_sorrel'),
      recipe: const Recipe(
        id: 'green-shchi-valid',
        title: 'Щавелевые щи',
        timeMin: 32,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Щавель', amount: 140, unit: Unit.g),
          RecipeIngredient(name: 'Картофель', amount: 4, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 60, unit: Unit.g),
          RecipeIngredient(name: 'Укроп', amount: 12, unit: Unit.g),
        ],
        steps: [
          'Подготовь щавель, картофель, яйца, лук и морковь, сначала мягко прогрей лук и морковь 4-5 минут.',
          'Влей воду и вари основу 16-18 минут, затем добавь яйца, а в последние 2-3 минуты добавь щавель.',
          'Сними с огня, доведи вкус и подай со сметаной и укропом.',
        ],
      ),
      recipeCanonicals: const {
        'щавель',
        'картофель',
        'яйцо',
        'лук',
        'морковь',
        'сметана',
        'укроп',
      },
    );

    expect(result.isValid, isTrue, reason: result.violations.join('\n'));
  });

  test('rejects green shchi when sorrel is boiled from the start', () {
    final result = validateChefDish(
      blueprint: _blueprint('green_shchi_sorrel'),
      recipe: const Recipe(
        id: 'green-shchi-flat',
        title: 'Щавелевые щи',
        timeMin: 30,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Щавель', amount: 140, unit: Unit.g),
          RecipeIngredient(name: 'Картофель', amount: 4, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Сметана', amount: 60, unit: Unit.g),
        ],
        steps: [
          'Подготовь щавель, картофель, яйца и лук.',
          'Влей воду, добавь щавель сразу и вари основу 18 минут.',
          'Сними с огня и подай со сметаной.',
        ],
      ),
      recipeCanonicals: const {'щавель', 'картофель', 'яйцо', 'лук', 'сметана'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Щавелевые щи должны добавлять щавель в самом конце, чтобы сохранить свежую кислоту.',
      ),
    );
  });

  test('accepts svekolnik with chilled beet base', () {
    final result = validateChefDish(
      blueprint: _blueprint('svekolnik'),
      recipe: const Recipe(
        id: 'svekolnik-valid',
        title: 'Свекольник холодный',
        timeMin: 28,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Свекла', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Кефир', amount: 700, unit: Unit.ml),
          RecipeIngredient(name: 'Картофель', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Огурцы', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Укроп', amount: 12, unit: Unit.g),
        ],
        steps: [
          'Отвари свеклу, картофель и яйца 10-12 минут, затем полностью остуди свекольную основу и остальные продукты.',
          'Нарежь свеклу, картофель, яйца, огурцы и укроп, сложи всё в большую миску.',
          'Влей кефир, доведи вкус и дай свекольнику постоять в холоде 5-7 минут, затем подавай охлаждённым.',
        ],
      ),
      recipeCanonicals: const {
        'свекла',
        'кефир',
        'картофель',
        'яйцо',
        'огурец',
        'укроп',
      },
    );

    expect(result.isValid, isTrue, reason: result.violations.join('\n'));
  });

  test('rejects svekolnik without chilled beet base', () {
    final result = validateChefDish(
      blueprint: _blueprint('svekolnik'),
      recipe: const Recipe(
        id: 'svekolnik-hot-base',
        title: 'Свекольник холодный',
        timeMin: 24,
        tags: ['soup'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Свекла', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Кефир', amount: 700, unit: Unit.ml),
          RecipeIngredient(name: 'Картофель', amount: 3, unit: Unit.pcs),
          RecipeIngredient(name: 'Яйца', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Огурцы', amount: 2, unit: Unit.pcs),
          RecipeIngredient(name: 'Укроп', amount: 12, unit: Unit.g),
        ],
        steps: [
          'Отвари свеклу, картофель и яйца 10-12 минут.',
          'Нарежь всё и сложи в миску.',
          'Влей кефир и сразу подавай холодным.',
        ],
      ),
      recipeCanonicals: const {
        'свекла',
        'кефир',
        'картофель',
        'яйцо',
        'огурец',
        'укроп',
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Свекольник требует отдельно сварить и полностью остудить свекольную основу.',
      ),
    );
  });

  test('accepts buckwheat rustic bowl with aromatic assembly', () {
    final result = validateChefDish(
      blueprint: _blueprint('grechka_rustic'),
      recipe: const Recipe(
        id: 'grechka-valid',
        title: 'Гречка по-домашнему',
        timeMin: 24,
        tags: ['grain'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Гречка', amount: 220, unit: Unit.g),
          RecipeIngredient(name: 'Грибы', amount: 220, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Укроп', amount: 10, unit: Unit.g),
        ],
        steps: [
          'Промой крупу и вари гречку 15-18 минут под крышкой, сначала прогрей добавки 4-5 минут.',
          'Добавь грибы к луку и моркови, затем вмешай основу, чтобы гречка впитала вкус.',
          'Дай блюду 1-2 минуты постоять и подавай горячим с укропом.',
        ],
      ),
      recipeCanonicals: const {'гречка', 'грибы', 'лук', 'морковь', 'укроп'},
    );

    expect(result.isValid, isTrue, reason: result.violations.join('\n'));
  });

  test('rejects buckwheat rustic bowl without aromatic assembly', () {
    final result = validateChefDish(
      blueprint: _blueprint('grechka_rustic'),
      recipe: const Recipe(
        id: 'grechka-flat',
        title: 'Гречка по-домашнему',
        timeMin: 14,
        tags: ['grain'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Гречка', amount: 220, unit: Unit.g),
          RecipeIngredient(name: 'Грибы', amount: 220, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Свари гречку.',
          'Сложи грибы и лук сверху.',
          'Подавай.',
        ],
      ),
      recipeCanonicals: const {'гречка', 'грибы', 'лук'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Гречка по-домашнему должна собираться через вмешивание готовой крупы в ароматическую базу.',
      ),
    );
  });

  test('accepts stewed cabbage with tomato depth and covered finish', () {
    final result = validateChefDish(
      blueprint: _blueprint('stewed_cabbage'),
      recipe: const Recipe(
        id: 'stewed-cabbage-valid',
        title: 'Тушёная капуста',
        timeMin: 28,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Капуста', amount: 800, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Колбаса', amount: 220, unit: Unit.g),
          RecipeIngredient(name: 'Томатная паста', amount: 45, unit: Unit.g),
        ],
        steps: [
          'Подготовь капусту, лук и морковь, прогрей в самом начале лук и морковь 4-5 минут.',
          'Добавь томатную пасту и колбасу, затем туши капусту на слабом огне под крышкой 20-25 минут, пока текстура не станет густой и насыщенной.',
          'Сними с огня, дай блюду пару минут постоять и подавай горячим.',
        ],
      ),
      recipeCanonicals: const {
        'капуста',
        'лук',
        'морковь',
        'колбаса',
        'томатная паста',
      },
    );

    expect(result.isValid, isTrue, reason: result.violations.join('\n'));
  });

  test('rejects stewed cabbage that drifts into cold mayo dish', () {
    final result = validateChefDish(
      blueprint: _blueprint('stewed_cabbage'),
      recipe: const Recipe(
        id: 'stewed-cabbage-cold',
        title: 'Тушёная капуста',
        timeMin: 12,
        tags: ['stew'],
        servingsBase: 3,
        ingredients: [
          RecipeIngredient(name: 'Капуста', amount: 800, unit: Unit.g),
          RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
          RecipeIngredient(name: 'Колбаса', amount: 220, unit: Unit.g),
          RecipeIngredient(name: 'Майонез', amount: 40, unit: Unit.g),
        ],
        steps: [
          'Смешай капусту с луком, морковью, колбасой и майонезом.',
          'Подавай холодной.',
        ],
      ),
      recipeCanonicals: const {
        'капуста',
        'лук',
        'морковь',
        'колбаса',
        'майонез',
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains('Тушёная капуста не должна уходить в майонезную логику салата.'),
    );
    expect(
      result.violations,
      contains(
          'Тушёная капуста не должна уходить в холодную подачу или запекание.'),
    );
  });
  test('accepts proper mors with separate juice and chilled finish', () {
    final result = validateChefDish(
      blueprint: _blueprint('mors'),
      recipe: const Recipe(
        id: 'mors-valid',
        title: 'Морс: Клюква',
        timeMin: 28,
        tags: ['drink', 'cold'],
        servingsBase: 4,
        ingredients: [
          RecipeIngredient(name: 'Клюква', amount: 250, unit: Unit.g),
          RecipeIngredient(name: 'Сахар', amount: 80, unit: Unit.g),
          RecipeIngredient(name: 'Лимон', amount: 1, unit: Unit.pcs),
        ],
        steps: [
          'Разомни клюкву, отдели сок через сито и убери его в холод.',
          'Залей ягодный жмых водой, добавь сахар и спокойно прогрей основу 8-10 минут без бурного кипения.',
          'Процеди ягодную основу, остуди до тёплого состояния и верни отложенный сок с лимоном.',
          'Охлади морс 2-3 часа и подавай хорошо холодным.',
        ],
      ),
      recipeCanonicals: const {'клюква', 'сахар', 'лимон'},
    );

    expect(result.isValid, isTrue);
  });

  test('rejects mors that drifts into milkshake', () {
    final result = validateChefDish(
      blueprint: _blueprint('mors'),
      recipe: const Recipe(
        id: 'mors-milkshake',
        title: 'Морс ягодный',
        timeMin: 10,
        tags: ['drink'],
        servingsBase: 2,
        ingredients: [
          RecipeIngredient(name: 'Клюква', amount: 200, unit: Unit.g),
          RecipeIngredient(name: 'Сахар', amount: 50, unit: Unit.g),
          RecipeIngredient(name: 'Молоко', amount: 300, unit: Unit.ml),
        ],
        steps: [
          'Разомни клюкву и сразу пробей её блендером с молоком и сахаром.',
          'Остуди и подавай холодным.',
        ],
      ),
      recipeCanonicals: const {'клюква', 'сахар', 'молоко'},
    );

    expect(result.isValid, isFalse);
    expect(
      result.violations,
      contains(
        'Морс не должен превращаться в молочный коктейль, соус или savoury-напиток.',
      ),
    );
  });
}

ChefBlueprint _blueprint(String id) {
  return chefBlueprints.firstWhere((blueprint) => blueprint.id == id);
}
