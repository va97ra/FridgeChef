import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/features/recipes/domain/chef_rules.dart';

void main() {
  test('chef rules reward aromatic base and shelf seasonings for soup', () {
    final assessment = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'курица', 'картофель', 'лук', 'морковь'},
      matchedCanonicals: const {'курица', 'картофель', 'лук', 'морковь'},
      supportCanonicals: const {'соль', 'перец', 'укроп'},
      displayByCanonical: const {
        'курица': 'Курица',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'соль': 'Соль',
        'перец': 'Перец',
        'укроп': 'Укроп',
      },
      steps: const [
        'Нарежь овощи и курицу.',
        'Вари на умеренном огне до мягкости.',
        'Подавай с укропом.',
      ],
    );

    expect(assessment.structureScore, greaterThan(0.7));
    expect(assessment.seasoningScore, greaterThan(0.6));
    expect(assessment.techniqueScore, greaterThan(0.6));
    expect(
      assessment.supportPlan.aromaticCanonicals,
      isNotEmpty,
    );
    expect(
      assessment.supportPlan.seasoningCanonicals,
      isNotEmpty,
    );
    expect(
      assessment.reasons.any((reason) => reason.contains('аромати')),
      isTrue,
    );
  });

  test('chef rules reward balanced borscht over flat beet soup', () {
    final flatBorscht = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'свекла', 'капуста', 'картофель', 'лук'},
      matchedCanonicals: const {'свекла', 'капуста', 'картофель', 'лук'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'свекла': 'Свекла',
        'капуста': 'Капуста',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Подготовь свеклу, капусту, картофель и лук.',
        'Влей воду и вари суп.',
        'Подавай.',
      ],
    );

    final properBorscht = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {
        'свекла',
        'капуста',
        'картофель',
        'лук',
        'морковь',
        'томатная паста',
        'сметана',
      },
      matchedCanonicals: const {
        'свекла',
        'капуста',
        'картофель',
        'лук',
        'морковь',
        'томатная паста',
      },
      supportCanonicals: const {'соль', 'перец', 'сметана', 'укроп'},
      displayByCanonical: const {
        'свекла': 'Свекла',
        'капуста': 'Капуста',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'томатная паста': 'Томатная паста',
        'сметана': 'Сметана',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Подготовь свеклу, капусту, картофель, морковь и лук, затем прогрей лук и вмешай томатную пасту.',
        'Влей воду и вари борщ 20-25 минут до мягкости овощей.',
        'В конце добавь сметану и укроп, затем подавай.',
      ],
    );

    expect(
        properBorscht.techniqueScore, greaterThan(flatBorscht.techniqueScore));
    expect(properBorscht.balanceScore, greaterThan(flatBorscht.balanceScore));
    expect(properBorscht.flavorScore, greaterThan(flatBorscht.flavorScore));
    expect(properBorscht.score, greaterThan(flatBorscht.score));
  });

  test('chef rules reward proper solyanka finish over flat sausage soup', () {
    final flatSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'колбаса', 'огурец', 'лук', 'томатная паста'},
      matchedCanonicals: const {'колбаса', 'огурец', 'лук', 'томатная паста'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'колбаса': 'Колбаса',
        'огурец': 'Огурцы',
        'лук': 'Лук',
        'томатная паста': 'Томатная паста',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Подготовь колбасу, огурцы и лук.',
        'Влей воду и вари суп 14-16 минут.',
        'Подавай.',
      ],
    );

    final properSolyanka = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {
        'колбаса',
        'огурец',
        'лук',
        'томатная паста',
        'оливки',
        'лимон',
      },
      matchedCanonicals: const {
        'колбаса',
        'огурец',
        'лук',
        'томатная паста',
        'оливки',
      },
      supportCanonicals: const {'соль', 'перец', 'лимон', 'сметана'},
      displayByCanonical: const {
        'колбаса': 'Колбаса',
        'огурец': 'Огурцы',
        'лук': 'Лук',
        'томатная паста': 'Томатная паста',
        'оливки': 'Оливки',
        'лимон': 'Лимон',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Подготовь колбасу, огурцы и лук, затем прогрей лук и томатную пасту.',
        'Влей воду, добавь мясную основу и вари солянку 14-16 минут.',
        'В конце добавь оливки и лимон, затем подавай со сметаной.',
      ],
    );

    expect(properSolyanka.techniqueScore, greaterThan(flatSoup.techniqueScore));
    expect(properSolyanka.balanceScore, greaterThan(flatSoup.balanceScore));
    expect(properSolyanka.flavorScore, greaterThan(flatSoup.flavorScore));
    expect(properSolyanka.score, greaterThan(flatSoup.score));
  });

  test('chef rules reward proper mushroom soup over flat watery version', () {
    final flatSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'грибы', 'картофель', 'лук'},
      matchedCanonicals: const {'грибы', 'картофель', 'лук'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'грибы': 'Грибы',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'соль': 'Соль',
      },
      steps: const [
        'Подготовь грибы, картофель и лук.',
        'Влей воду и вари суп 18 минут.',
        'Подавай.',
      ],
    );

    final properSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {
        'грибы',
        'картофель',
        'лук',
        'морковь',
        'сметана',
        'укроп',
      },
      matchedCanonicals: const {
        'грибы',
        'картофель',
        'лук',
        'морковь',
      },
      supportCanonicals: const {
        'соль',
        'перец',
        'лавровый лист',
        'сметана',
        'укроп',
      },
      displayByCanonical: const {
        'грибы': 'Грибы',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'сметана': 'Сметана',
        'укроп': 'Укроп',
        'лавровый лист': 'Лавровый лист',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Сначала прогрей лук и морковь 4-5 минут, затем добавь грибы и выпарь их 4-6 минут.',
        'Влей воду, добавь картофель и вари грибной суп 16-18 минут на слабом огне.',
        'В конце добавь сметану, укроп и подавай.',
      ],
    );

    expect(properSoup.techniqueScore, greaterThan(flatSoup.techniqueScore));
    expect(properSoup.balanceScore, greaterThan(flatSoup.balanceScore));
    expect(properSoup.flavorScore, greaterThan(flatSoup.flavorScore));
    expect(properSoup.score, greaterThan(flatSoup.score));
    expect(
      flatSoup.warnings.any((warning) => warning.contains('грибному супу')),
      isTrue,
    );
  });

  test('chef rules reward proper pea smoked soup over flat pea sausage soup',
      () {
    final flatSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'горох', 'колбаса', 'лук', 'морковь'},
      matchedCanonicals: const {'горох', 'колбаса', 'лук', 'морковь'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'горох': 'Горох',
        'колбаса': 'Колбаса',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'соль': 'Соль',
      },
      steps: const [
        'Подготовь горох, колбасу, лук и морковь.',
        'Влей воду и вари суп 18 минут.',
        'Подавай.',
      ],
    );

    final properSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {
        'горох',
        'колбаса',
        'картофель',
        'лук',
        'морковь',
        'сметана',
        'укроп',
      },
      matchedCanonicals: const {
        'горох',
        'колбаса',
        'картофель',
        'лук',
        'морковь',
      },
      supportCanonicals: const {
        'соль',
        'перец',
        'лавровый лист',
        'сметана',
        'укроп',
      },
      displayByCanonical: const {
        'горох': 'Горох',
        'колбаса': 'Копченая колбаса',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'сметана': 'Сметана',
        'укроп': 'Укроп',
        'лавровый лист': 'Лавровый лист',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Промой горох, картофель пока держи отдельно, сначала мягко прогрей лук и морковь 4-5 минут и затем добавь копченую колбасу еще на 1-2 минуты.',
        'Влей воду, добавь горох и вари гороховый суп 35-45 минут на спокойном огне, а картофель положи на последние 12-15 минут.',
        'Сними с огня, подай со сметаной и укропом.',
      ],
    );

    expect(properSoup.techniqueScore, greaterThan(flatSoup.techniqueScore));
    expect(properSoup.balanceScore, greaterThan(flatSoup.balanceScore));
    expect(properSoup.flavorScore, greaterThan(flatSoup.flavorScore));
    expect(properSoup.score, greaterThan(flatSoup.score));
    expect(
      flatSoup.warnings.any((warning) => warning.contains('гороховому супу')),
      isTrue,
    );
  });

  test('chef rules penalize structurally weak dish', () {
    final assessment = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'соль', 'сахар'},
      matchedCanonicals: const {'соль', 'сахар'},
      supportCanonicals: const {},
      displayByCanonical: const {
        'соль': 'Соль',
        'сахар': 'Сахар',
      },
      steps: const ['Смешай и подай.'],
    );

    expect(assessment.score, lessThan(0.45));
    expect(
      assessment.warnings,
      contains('не хватает опорного ингредиента'),
    );
  });

  test('chef rules penalize salad without dressing support', () {
    final weakSalad = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'огурец', 'помидор'},
      matchedCanonicals: const {'огурец', 'помидор'},
      supportCanonicals: const {},
      displayByCanonical: const {
        'огурец': 'Огурец',
        'помидор': 'Помидор',
      },
      steps: const ['Нарежь овощи.', 'Смешай и подай.'],
    );

    final balancedSalad = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'огурец', 'помидор'},
      matchedCanonicals: const {'огурец', 'помидор'},
      supportCanonicals: const {'оливковое масло', 'лимон', 'соль'},
      displayByCanonical: const {
        'огурец': 'Огурец',
        'помидор': 'Помидор',
        'оливковое масло': 'Оливковое масло',
        'лимон': 'Лимон',
        'соль': 'Соль',
      },
      steps: const ['Нарежь овощи.', 'Смешай и заправь перед подачей.'],
    );

    expect(
      weakSalad.warnings,
      contains('для салата не хватает заправки или соуса'),
    );
    expect(weakSalad.score, lessThan(balancedSalad.score));
    expect(balancedSalad.balanceScore, greaterThan(weakSalad.balanceScore));
  });

  test('chef rules reward flavor-balanced pasta over dry neutral base', () {
    final balancedPasta = assessChefRules(
      profile: DishProfile.pasta,
      recipeCanonicals: const {'макароны', 'сыр', 'помидор'},
      matchedCanonicals: const {'макароны', 'сыр', 'помидор'},
      supportCanonicals: const {'оливковое масло', 'соль'},
      displayByCanonical: const {
        'макароны': 'Макароны',
        'сыр': 'Сыр',
        'помидор': 'Помидор',
        'оливковое масло': 'Оливковое масло',
        'соль': 'Соль',
      },
      steps: const [
        'Отвари макароны.',
        'Смешай с сыром и томатами.',
        'Подавай.'
      ],
    );

    final dryPasta = assessChefRules(
      profile: DishProfile.pasta,
      recipeCanonicals: const {'макароны'},
      matchedCanonicals: const {'макароны'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'макароны': 'Макароны',
        'соль': 'Соль',
      },
      steps: const ['Отвари макароны.', 'Подавай.'],
    );

    expect(balancedPasta.flavorScore, greaterThan(dryPasta.flavorScore));
    expect(balancedPasta.score, greaterThan(dryPasta.score));
    expect(
      dryPasta.warnings.any((warning) => warning.contains('не хватает')),
      isTrue,
    );
  });

  test('chef rules penalize chicken skillet without proper heat treatment', () {
    final weakSkillet = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'курица', 'лук'},
      matchedCanonicals: const {'курица', 'лук'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'курица': 'Курица',
        'лук': 'Лук',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Нарежь курицу и лук.',
        'Смешай и подай.',
      ],
    );

    final properSkillet = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'курица', 'лук'},
      matchedCanonicals: const {'курица', 'лук'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'курица': 'Курица',
        'лук': 'Лук',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Нарежь курицу и лук.',
        'Обжарь курицу до готовности, затем добавь лук.',
        'Приправь и подавай горячей.',
      ],
    );

    expect(
        properSkillet.techniqueScore, greaterThan(weakSkillet.techniqueScore));
    expect(properSkillet.score, greaterThan(weakSkillet.score));
    expect(
      weakSkillet.warnings,
      contains('основному белку не хватает явной термообработки до готовности'),
    );
  });

  test('chef rules reward baked fish with acid and moisture protection', () {
    final weakBake = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'рыба', 'картофель'},
      matchedCanonicals: const {'рыба', 'картофель'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'картофель': 'Картофель',
        'соль': 'Соль',
      },
      steps: const [
        'Выложи рыбу и картофель в форму.',
        'Запекай и подай.',
      ],
    );

    final strongBake = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'рыба', 'картофель', 'лимон', 'масло'},
      matchedCanonicals: const {'рыба', 'картофель', 'лимон', 'масло'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'картофель': 'Картофель',
        'лимон': 'Лимон',
        'масло': 'Масло',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Сбрызни рыбу лимоном и маслом.',
        'Накрой форму и запекай до готовности.',
        'Открой форму, дай слегка подрумяниться и подай.',
      ],
    );

    expect(strongBake.techniqueScore, greaterThan(weakBake.techniqueScore));
    expect(strongBake.flavorScore, greaterThan(weakBake.flavorScore));
    expect(strongBake.score, greaterThan(weakBake.score));
    expect(
      weakBake.warnings.any((warning) => warning.contains('рыбе часто нужен')),
      isTrue,
    );
  });

  test('chef rules reward crunchy herby salad over soft flat salad', () {
    final livelySalad = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'капуста', 'яблоко', 'йогурт', 'укроп'},
      matchedCanonicals: const {'капуста', 'яблоко', 'йогурт', 'укроп'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'капуста': 'Капуста',
        'яблоко': 'Яблоко',
        'йогурт': 'Йогурт',
        'укроп': 'Укроп',
        'соль': 'Соль',
      },
      steps: const [
        'Нашинкуй капусту.',
        'Смешай с яблоком.',
        'Заправь йогуртом и укропом перед подачей.',
      ],
    );

    final flatSalad = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'помидор', 'сыр'},
      matchedCanonicals: const {'помидор', 'сыр'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'помидор': 'Помидор',
        'сыр': 'Сыр',
        'соль': 'Соль',
      },
      steps: const [
        'Нарежь помидор.',
        'Смешай с сыром и подай.',
      ],
    );

    expect(livelySalad.flavorScore, greaterThan(flatSalad.flavorScore));
    expect(livelySalad.score, greaterThan(flatSalad.score));
    expect(
      livelySalad.reasons.any((reason) => reason.contains('хруст')),
      isTrue,
    );
    expect(
      livelySalad.warnings.any((warning) => warning.contains('квашен')),
      isFalse,
    );
  });

  test(
      'chef rules do not mistake cucumber yogurt salad for lightly salted preserve',
      () {
    final freshCucumberSalad = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'огурец', 'йогурт', 'укроп', 'чеснок'},
      matchedCanonicals: const {'огурец', 'йогурт', 'укроп', 'чеснок'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'огурец': 'Огурец',
        'йогурт': 'Йогурт',
        'укроп': 'Укроп',
        'чеснок': 'Чеснок',
        'соль': 'Соль',
      },
      steps: const [
        'Нарежь огурцы тонкими полукружьями и слегка посоли.',
        'Смешай йогурт с чесноком и укропом.',
        'Заправь огурцы соусом перед подачей и подавай охлаждёнными.',
      ],
    );

    expect(freshCucumberSalad.score, greaterThan(0.35));
    expect(
      freshCucumberSalad.reasons.any((reason) => reason.contains('салат')),
      isTrue,
    );
    expect(
      freshCucumberSalad.warnings
          .any((warning) => warning.contains('малосоль')),
      isFalse,
    );
  });

  test('chef rules reward fish with herbs and acid over plain fish', () {
    final plainFish = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'рыба', 'картофель'},
      matchedCanonicals: const {'рыба', 'картофель'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'картофель': 'Картофель',
        'соль': 'Соль',
      },
      steps: const [
        'Выложи в форму.',
        'Запекай до готовности.',
        'Подавай.',
      ],
    );

    final brightFish = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'рыба', 'лимон', 'укроп', 'сметана'},
      matchedCanonicals: const {'рыба', 'лимон', 'укроп', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'лимон': 'Лимон',
        'укроп': 'Укроп',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Сбрызни рыбу лимоном.',
        'Накрой и запекай до готовности.',
        'Доведи сметаной с укропом и подай.',
      ],
    );

    expect(brightFish.balanceScore, greaterThan(plainFish.balanceScore));
    expect(brightFish.flavorScore, greaterThan(plainFish.flavorScore));
    expect(brightFish.score, greaterThan(plainFish.score));
  });

  test('chef rules penalize sweet breakfast without fresh contrast', () {
    final flatBreakfast = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'овсяные хлопья', 'молоко', 'сахар'},
      matchedCanonicals: const {'овсяные хлопья', 'молоко', 'сахар'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'овсяные хлопья': 'Овсяные хлопья',
        'молоко': 'Молоко',
        'сахар': 'Сахар',
        'соль': 'Соль',
      },
      steps: const [
        'Свари кашу на молоке.',
        'Добавь сахар и подай.',
      ],
    );

    final brightBreakfast = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {
        'овсяные хлопья',
        'молоко',
        'апельсин',
        'корица'
      },
      matchedCanonicals: const {
        'овсяные хлопья',
        'молоко',
        'апельсин',
        'корица'
      },
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'овсяные хлопья': 'Овсяные хлопья',
        'молоко': 'Молоко',
        'апельсин': 'Апельсин',
        'корица': 'Корица',
        'соль': 'Соль',
      },
      steps: const [
        'Свари кашу на молоке.',
        'Добавь апельсин и корицу вне сильного кипения.',
        'Подавай сразу.',
      ],
    );

    expect(
      flatBreakfast.warnings
          .any((warning) => warning.contains('свежего контраста')),
      isTrue,
    );
    expect(brightBreakfast.flavorScore, greaterThan(flatBreakfast.flavorScore));
    expect(brightBreakfast.score, greaterThan(flatBreakfast.score));
  });

  test('chef rules reward chilled kefir soup over flat warm assembly', () {
    final flatSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'кефир', 'картофель', 'яйцо', 'огурец'},
      matchedCanonicals: const {'кефир', 'картофель', 'яйцо', 'огурец'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'кефир': 'Кефир',
        'картофель': 'Картофель',
        'яйцо': 'Яйца',
        'огурец': 'Огурцы',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Смешай кефир, картофель, яйца и огурцы.',
        'Прогрей всё вместе и подавай.',
      ],
    );

    final properSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'кефир', 'картофель', 'яйцо', 'огурец', 'укроп'},
      matchedCanonicals: const {
        'кефир',
        'картофель',
        'яйцо',
        'огурец',
        'укроп'
      },
      supportCanonicals: const {'соль', 'перец', 'сметана'},
      displayByCanonical: const {
        'кефир': 'Кефир',
        'картофель': 'Картофель',
        'яйцо': 'Яйца',
        'огурец': 'Огурцы',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
        'сметана': 'Сметана',
      },
      steps: const [
        'Отвари картофель и яйца, затем остуди их.',
        'Нарежь огурцы и укроп.',
        'Влей кефир, доведи солью и перцем, дай постоять в холоде и подавай холодной.',
      ],
    );

    expect(properSoup.techniqueScore, greaterThan(flatSoup.techniqueScore));
    expect(properSoup.balanceScore, greaterThan(flatSoup.balanceScore));
    expect(properSoup.score, greaterThan(flatSoup.score));
    expect(
      flatSoup.warnings.any((warning) => warning.contains('охлажд')),
      isTrue,
    );
  });

  test('chef rules reward chilled kvass soup over warm flat assembly', () {
    final flatSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'квас', 'картофель', 'яйцо', 'огурец'},
      matchedCanonicals: const {'квас', 'картофель', 'яйцо', 'огурец'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'квас': 'Квас',
        'картофель': 'Картофель',
        'яйцо': 'Яйца',
        'огурец': 'Огурцы',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Смешай квас, картофель, яйца и огурцы.',
        'Прогрей всё вместе и подавай.',
      ],
    );

    final properSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'квас', 'картофель', 'яйцо', 'огурец', 'укроп'},
      matchedCanonicals: const {'квас', 'картофель', 'яйцо', 'огурец', 'укроп'},
      supportCanonicals: const {'соль', 'перец', 'сметана'},
      displayByCanonical: const {
        'квас': 'Квас',
        'картофель': 'Картофель',
        'яйцо': 'Яйца',
        'огурец': 'Огурцы',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
        'сметана': 'Сметана',
      },
      steps: const [
        'Отвари картофель и яйца, затем остуди их.',
        'Нарежь огурцы и укроп.',
        'Влей квас, доведи солью и перцем, дай постоять в холоде и подавай холодной.',
      ],
    );

    expect(properSoup.techniqueScore, greaterThan(flatSoup.techniqueScore));
    expect(properSoup.flavorScore, greaterThan(flatSoup.flavorScore));
    expect(properSoup.score, greaterThan(flatSoup.score));
  });

  test('chef rules reward rested blini batter over rushed frying', () {
    final rushedBlini = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'мука', 'молоко', 'яйцо'},
      matchedCanonicals: const {'мука', 'молоко', 'яйцо'},
      supportCanonicals: const {'соль', 'масло'},
      displayByCanonical: const {
        'мука': 'Мука',
        'молоко': 'Молоко',
        'яйцо': 'Яйца',
        'соль': 'Соль',
        'масло': 'Масло',
      },
      steps: const [
        'Сразу смешай муку, молоко и яйца.',
        'Жарь на сковороде и подавай.',
      ],
    );

    final properBlini = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'мука', 'молоко', 'яйцо', 'сахар'},
      matchedCanonicals: const {'мука', 'молоко', 'яйцо', 'сахар'},
      supportCanonicals: const {'соль', 'масло', 'сметана'},
      displayByCanonical: const {
        'мука': 'Мука',
        'молоко': 'Молоко',
        'яйцо': 'Яйца',
        'сахар': 'Сахар',
        'соль': 'Соль',
        'масло': 'Масло',
        'сметана': 'Сметана',
      },
      steps: const [
        'Размешай муку, молоко и яйца в тесто без комков.',
        'Дай тесту постоять 8-10 минут.',
        'Выпекай блины на слегка смазанной сковороде по 1-2 минуты с каждой стороны и подавай со сметаной.',
      ],
    );

    expect(properBlini.techniqueScore, greaterThan(rushedBlini.techniqueScore));
    expect(properBlini.score, greaterThan(rushedBlini.score));
    expect(
      rushedBlini.warnings.any((warning) => warning.contains('отдых')),
      isTrue,
    );
  });

  test('chef rules reward thick portioned oladyi batter over flat fry-up', () {
    final flatOladyi = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'мука', 'кефир', 'яйцо'},
      matchedCanonicals: const {'мука', 'кефир', 'яйцо'},
      supportCanonicals: const {'соль', 'масло'},
      displayByCanonical: const {
        'мука': 'Мука',
        'кефир': 'Кефир',
        'яйцо': 'Яйца',
        'соль': 'Соль',
        'масло': 'Масло',
      },
      steps: const [
        'Размешай муку, кефир и яйца.',
        'Вылей всё на сковороду и обжарь с двух сторон.',
      ],
    );

    final properOladyi = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'мука', 'кефир', 'яйцо', 'сахар'},
      matchedCanonicals: const {'мука', 'кефир', 'яйцо', 'сахар'},
      supportCanonicals: const {'соль', 'масло', 'сметана'},
      displayByCanonical: const {
        'мука': 'Мука',
        'кефир': 'Кефир',
        'яйцо': 'Яйца',
        'сахар': 'Сахар',
        'соль': 'Соль',
        'масло': 'Масло',
        'сметана': 'Сметана',
      },
      steps: const [
        'Размешай муку, кефир и яйца в густое тесто без комков.',
        'Дай тесту постоять 5-7 минут.',
        'Выкладывай тесто ложкой небольшими порциями на сковороду и жарь по 2-3 минуты с каждой стороны, подавай со сметаной.',
      ],
    );

    expect(properOladyi.techniqueScore, greaterThan(flatOladyi.techniqueScore));
    expect(properOladyi.score, greaterThan(flatOladyi.score));
  });

  test('chef rules reward shaped syrniki over spooned curd batter', () {
    final batterSyrniki = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'творог', 'яйцо'},
      matchedCanonicals: const {'творог', 'яйцо'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'творог': 'Творог',
        'яйцо': 'Яйца',
        'соль': 'Соль',
      },
      steps: const [
        'Размешай творог с яйцом в густое тесто.',
        'Выкладывай массу ложкой на сковороду и жарь.',
      ],
    );

    final properSyrniki = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'творог', 'яйцо', 'сметана', 'сахар'},
      matchedCanonicals: const {'творог', 'яйцо', 'сахар'},
      supportCanonicals: const {'соль', 'сметана'},
      displayByCanonical: const {
        'творог': 'Творог',
        'яйцо': 'Яйца',
        'сметана': 'Сметана',
        'сахар': 'Сахар',
        'соль': 'Соль',
      },
      steps: const [
        'Соедини творог с яйцом и собери плотную творожную массу без лишней влаги.',
        'Сформируй небольшие шайбы влажными руками и обжарь их по 2-3 минуты с каждой стороны.',
        'Подавай со сметаной.',
      ],
    );

    expect(
      properSyrniki.techniqueScore,
      greaterThan(batterSyrniki.techniqueScore),
    );
    expect(properSyrniki.balanceScore, greaterThan(batterSyrniki.balanceScore));
    expect(properSyrniki.score, greaterThan(batterSyrniki.score));
    expect(
      batterSyrniki.warnings.any(
        (warning) =>
            warning.contains('сырник') || warning.contains('технику оладий'),
      ),
      isTrue,
    );
  });

  test('chef rules reward squeezed draniki over wet potato batter', () {
    final wetDraniki = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'картофель', 'лук', 'яйцо'},
      matchedCanonicals: const {'картофель', 'лук', 'яйцо'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'картофель': 'Картофель',
        'лук': 'Лук',
        'яйцо': 'Яйца',
        'соль': 'Соль',
      },
      steps: const [
        'Натри картофель и лук, затем дай массе постоять.',
        'Жарь как густое тесто на сковороде.',
      ],
    );

    final properDraniki = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'картофель', 'лук', 'яйцо', 'сметана'},
      matchedCanonicals: const {'картофель', 'лук', 'яйцо'},
      supportCanonicals: const {'соль', 'перец', 'сметана'},
      displayByCanonical: const {
        'картофель': 'Картофель',
        'лук': 'Лук',
        'яйцо': 'Яйца',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Натри картофель, мелко нарежь лук и слегка отожми массу.',
        'Выкладывай небольшие порции на сковороду и жарь драники по 3-4 минуты с каждой стороны.',
        'Подавай со сметаной.',
      ],
    );

    expect(
      properDraniki.techniqueScore,
      greaterThan(wetDraniki.techniqueScore),
    );
    expect(properDraniki.flavorScore, greaterThan(wetDraniki.flavorScore));
    expect(properDraniki.score, greaterThan(wetDraniki.score));
    expect(
      wetDraniki.warnings.any(
        (warning) =>
            warning.contains('влаг') || warning.contains('блинного теста'),
      ),
      isTrue,
    );
  });

  test('chef rules reward layered chilled liver cake over flat hot liver mass',
      () {
    final flatLiverCake = assessChefRules(
      profile: DishProfile.general,
      recipeCanonicals: const {
        'печень',
        'яйцо',
        'мука',
        'лук',
        'морковь',
        'майонез',
      },
      matchedCanonicals: const {
        'печень',
        'яйцо',
        'мука',
        'лук',
        'морковь',
        'майонез',
      },
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'печень': 'Печень',
        'яйцо': 'Яйца',
        'мука': 'Мука',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'майонез': 'Майонез',
        'соль': 'Соль',
      },
      steps: const [
        'Пробей печень с яйцами и мукой.',
        'Смешай печеночную массу с луком, морковью и майонезом на сковороде.',
        'Подавай горячим.',
      ],
    );

    final properLiverCake = assessChefRules(
      profile: DishProfile.general,
      recipeCanonicals: const {
        'печень',
        'яйцо',
        'мука',
        'лук',
        'морковь',
        'майонез',
        'укроп',
      },
      matchedCanonicals: const {
        'печень',
        'яйцо',
        'мука',
        'лук',
        'морковь',
        'майонез',
      },
      supportCanonicals: const {'соль', 'перец', 'укроп'},
      displayByCanonical: const {
        'печень': 'Печень',
        'яйцо': 'Яйца',
        'мука': 'Мука',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'майонез': 'Майонез',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Пробей печень с яйцами и мукой в гладкое печеночное тесто.',
        'Мелко нарежь лук и морковь, обжарь овощную прослойку и отдельно жарь тонкие коржи по 1-2 минуты с каждой стороны.',
        'Собери печеночный торт слоями с майонезом, каждый корж отдельно остуди и убери в холодильник на 2-3 часа.',
        'Подавай холодным с укропом.',
      ],
    );

    expect(
      properLiverCake.techniqueScore,
      greaterThan(flatLiverCake.techniqueScore),
    );
    expect(
      properLiverCake.balanceScore,
      greaterThan(flatLiverCake.balanceScore),
    );
    expect(
      properLiverCake.flavorScore,
      greaterThan(flatLiverCake.flavorScore),
    );
    expect(properLiverCake.score, greaterThan(flatLiverCake.score));
    expect(
      flatLiverCake.warnings.any(
        (warning) => warning.contains('печеночному торту'),
      ),
      isTrue,
    );
  });

  test('chef rules reward proper charlotte over dense apple batter bake', () {
    final flatCharlotte = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'яблоко', 'яйцо', 'мука', 'сахар'},
      matchedCanonicals: const {'яблоко', 'яйцо', 'мука'},
      supportCanonicals: const {'сахар'},
      displayByCanonical: const {
        'яблоко': 'Яблоко',
        'яйцо': 'Яйца',
        'мука': 'Мука',
        'сахар': 'Сахар',
      },
      steps: const [
        'Смешай яблоки, яйца, сахар и муку в густую массу.',
        'Переложи всё в форму и запекай 25 минут.',
        'Сразу подавай.',
      ],
    );

    final properCharlotte = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {
        'яблоко',
        'яйцо',
        'мука',
        'сахар',
        'корица',
        'масло сливочное',
      },
      matchedCanonicals: const {'яблоко', 'яйцо', 'мука'},
      supportCanonicals: const {'сахар', 'корица', 'масло сливочное'},
      displayByCanonical: const {
        'яблоко': 'Яблоко',
        'яйцо': 'Яйца',
        'мука': 'Мука',
        'сахар': 'Сахар',
        'корица': 'Корица',
        'масло сливочное': 'Сливочное масло',
      },
      steps: const [
        'Смажь форму сливочным маслом и разложи яблоки в форме ровным слоем.',
        'Взбей яйца с сахаром 4-5 минут в светлую пышную массу и аккуратно вмешай муку лопаткой.',
        'Вылей тесто на яблоки и запекай шарлотку 30-35 минут до золотистой корочки.',
        'Дай шарлотке постоять 10 минут перед нарезкой и подавай тёплой с корицей.',
      ],
    );

    expect(
      properCharlotte.techniqueScore,
      greaterThan(flatCharlotte.techniqueScore),
    );
    expect(
      properCharlotte.balanceScore,
      greaterThan(flatCharlotte.balanceScore),
    );
    expect(
      properCharlotte.flavorScore,
      greaterThan(flatCharlotte.flavorScore),
    );
    expect(properCharlotte.score, greaterThan(flatCharlotte.score));
    expect(
      flatCharlotte.warnings.any(
        (warning) => warning.contains('шарлотк'),
      ),
      isTrue,
    );
  });

  test(
      'chef rules reward proper sauerkraut preserve over rushed cabbage salt mix',
      () {
    final flatSauerkraut = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'капуста', 'соль'},
      matchedCanonicals: const {'капуста'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'капуста': 'Капуста',
        'соль': 'Соль',
      },
      steps: const [
        'Нашинкуй капусту.',
        'Сразу переложи в миску и подавай.',
      ],
    );

    final properSauerkraut = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'капуста', 'морковь', 'соль'},
      matchedCanonicals: const {'капуста', 'морковь'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'капуста': 'Капуста',
        'морковь': 'Морковь',
        'соль': 'Соль',
      },
      steps: const [
        'Тонко нашинкуй капусту и натри морковь. Добавь соль и перетри капусту руками, пока она не даст сок.',
        'Плотно уложи капусту в банку, утрамбуй и прижми так, чтобы капуста оставалась под соком.',
        'Оставь капусту при комнатной температуре на 2-3 дня и прокалывай её, выпуская газ.',
        'Убери квашеную капусту в холод и подавай холодной.',
      ],
    );

    expect(
      properSauerkraut.techniqueScore,
      greaterThan(flatSauerkraut.techniqueScore),
    );
    expect(
      properSauerkraut.balanceScore,
      greaterThan(flatSauerkraut.balanceScore),
    );
    expect(
      properSauerkraut.flavorScore,
      greaterThan(flatSauerkraut.flavorScore),
    );
    expect(properSauerkraut.score, greaterThan(flatSauerkraut.score));
    expect(
      flatSauerkraut.warnings.any(
        (warning) => warning.contains('квашен'),
      ),
      isTrue,
    );
  });

  test(
      'chef rules reward proper lightly salted cucumbers over rushed cucumber mix',
      () {
    final flatCucumbers = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'огурец', 'укроп', 'чеснок', 'соль'},
      matchedCanonicals: const {'огурец', 'укроп', 'чеснок'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'огурец': 'Огурцы',
        'укроп': 'Укроп',
        'чеснок': 'Чеснок',
        'соль': 'Соль',
      },
      steps: const [
        'Нарежь огурцы.',
        'Смешай с укропом и чесноком.',
        'Подавай сразу.',
      ],
    );

    final properCucumbers = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'огурец', 'укроп', 'чеснок', 'соль'},
      matchedCanonicals: const {'огурец', 'укроп', 'чеснок'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'огурец': 'Огурцы',
        'укроп': 'Укроп',
        'чеснок': 'Чеснок',
        'соль': 'Соль',
      },
      steps: const [
        'Срежь кончики у огурцов и уложи огурцы в контейнер слоями с укропом и чесноком.',
        'Раствори соль в холодной воде и залей огурцы рассолом так, чтобы они были полностью покрыты.',
        'Оставь огурцы при комнатной температуре на 8-12 часов или на ночь.',
        'После этого убери малосольные огурцы в холод минимум на 2-3 часа и подавай охлаждёнными.',
      ],
    );

    expect(
      properCucumbers.techniqueScore,
      greaterThan(flatCucumbers.techniqueScore),
    );
    expect(properCucumbers.score, greaterThan(flatCucumbers.score));
    expect(
      flatCucumbers.warnings.any(
        (warning) => warning.contains('малосоль'),
      ),
      isTrue,
    );
  });

  test('chef rules reward structured lazy cabbage rolls over flat mince stew',
      () {
    final flatGolubtsy = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'фарш', 'капуста', 'рис'},
      matchedCanonicals: const {'фарш', 'капуста', 'рис'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'фарш': 'Фарш',
        'капуста': 'Капуста',
        'рис': 'Рис',
        'соль': 'Соль',
      },
      steps: const [
        'Сложи фарш, капусту и рис вместе.',
        'Туши до готовности.',
        'Подавай.',
      ],
    );

    final properGolubtsy = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {
        'фарш',
        'капуста',
        'рис',
        'лук',
        'морковь',
        'томатная паста',
        'сметана',
      },
      matchedCanonicals: const {
        'фарш',
        'капуста',
        'рис',
        'лук',
        'морковь',
        'томатная паста',
      },
      supportCanonicals: const {'соль', 'перец', 'сметана'},
      displayByCanonical: const {
        'фарш': 'Фарш',
        'капуста': 'Капуста',
        'рис': 'Рис',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'томатная паста': 'Томатная паста',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Прогрей лук и морковь 4-5 минут, затем соедини фарш, рис и капусту в плотную основу для ленивых голубцов.',
        'Добавь томатную пасту и туши ленивые голубцы под крышкой 18-22 минуты на слабом огне.',
        'В конце подай со сметаной и дай блюду постоять 3-4 минуты.',
      ],
    );

    expect(
      properGolubtsy.techniqueScore,
      greaterThan(flatGolubtsy.techniqueScore),
    );
    expect(properGolubtsy.balanceScore, greaterThan(flatGolubtsy.balanceScore));
    expect(properGolubtsy.flavorScore, greaterThan(flatGolubtsy.flavorScore));
    expect(properGolubtsy.score, greaterThan(flatGolubtsy.score));
  });

  test('chef rules reward full home cutlet dinner over flat mince fry-up', () {
    final flatCutlets = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'фарш', 'гречка'},
      matchedCanonicals: const {'фарш', 'гречка'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'фарш': 'Фарш',
        'гречка': 'Гречка',
        'соль': 'Соль',
      },
      steps: const [
        'Смешай всё вместе.',
        'Обжарь и подавай.',
      ],
    );

    final properCutlets = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'фарш', 'гречка', 'лук', 'морковь', 'сметана'},
      matchedCanonicals: const {'фарш', 'гречка', 'лук', 'морковь'},
      supportCanonicals: const {'соль', 'перец', 'сметана'},
      displayByCanonical: const {
        'фарш': 'Фарш',
        'гречка': 'Гречка',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Промой гречку и вари гарнир 15-18 минут, одновременно мягко прогрей лук и морковь 4-5 минут.',
        'Соедини фарш с овощной поджаркой, сформируй котлеты и обжарь их по 4-5 минут с каждой стороны.',
        'Доведи котлеты ещё 6-8 минут на мягком огне, дай им отдохнуть 1-2 минуты и подавай вместе с гарниром и сметаной.',
      ],
    );

    expect(
      properCutlets.techniqueScore,
      greaterThan(flatCutlets.techniqueScore),
    );
    expect(properCutlets.balanceScore, greaterThan(flatCutlets.balanceScore));
    expect(properCutlets.flavorScore, greaterThan(flatCutlets.flavorScore));
    expect(properCutlets.score, greaterThan(flatCutlets.score));
  });

  test('chef rules reward layered zharkoe over flat potato meat boil', () {
    final flatZharkoe = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'говядина', 'картофель', 'лук'},
      matchedCanonicals: const {'говядина', 'картофель', 'лук'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'соль': 'Соль',
      },
      steps: const [
        'Сложи говядину, картофель и лук вместе.',
        'Влей воду и туши до готовности.',
        'Подавай.',
      ],
    );

    final properZharkoe = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {
        'говядина',
        'картофель',
        'лук',
        'морковь',
        'сметана',
        'чеснок',
      },
      matchedCanonicals: const {
        'говядина',
        'картофель',
        'лук',
        'морковь',
      },
      supportCanonicals: const {'соль', 'перец', 'сметана', 'чеснок'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'сметана': 'Сметана',
        'чеснок': 'Чеснок',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Прогрей лук и морковь 4-5 минут, затем обжарь говядину ещё 5-6 минут до уверенного цвета.',
        'Добавь картофель, долей немного воды и туши жаркое под крышкой 22-26 минут.',
        'В конце добавь сметану и чеснок, затем дай блюду постоять 3-4 минуты.',
      ],
    );

    expect(
      properZharkoe.techniqueScore,
      greaterThan(flatZharkoe.techniqueScore),
    );
    expect(properZharkoe.balanceScore, greaterThan(flatZharkoe.balanceScore));
    expect(properZharkoe.flavorScore, greaterThan(flatZharkoe.flavorScore));
    expect(properZharkoe.score, greaterThan(flatZharkoe.score));
  });

  test('chef rules reward real zrazy over flat mince cutlets with egg', () {
    final flatZrazy = assessChefRules(
      profile: DishProfile.stew,
      title: 'Зразы по-домашнему',
      recipeCanonicals: const {'фарш', 'гречка', 'яйцо'},
      matchedCanonicals: const {'фарш', 'гречка', 'яйцо'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'фарш': 'Фарш',
        'гречка': 'Гречка',
        'яйцо': 'Яйцо',
        'соль': 'Соль',
      },
      steps: const [
        'Смешай фарш и яйцо.',
        'Сформируй котлеты и обжарь.',
        'Подавай с гарниром.',
      ],
    );

    final properZrazy = assessChefRules(
      profile: DishProfile.stew,
      title: 'Зразы по-домашнему',
      recipeCanonicals: const {'фарш', 'гречка', 'яйцо', 'лук', 'сметана'},
      matchedCanonicals: const {'фарш', 'гречка', 'яйцо', 'лук'},
      supportCanonicals: const {'соль', 'перец', 'сметана'},
      displayByCanonical: const {
        'фарш': 'Фарш',
        'гречка': 'Гречка',
        'яйцо': 'Яйцо',
        'лук': 'Лук',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Отвари гречку на гарнир 15-18 минут, а яйца 8-9 минут и мелко наруби их с луком для начинки.',
        'Соедини фарш с луком, затем расплющи порции, уложи начинку в центр, плотно закрой края и сформируй зразы.',
        'Обжарь зразы по 4-5 минут с каждой стороны, доведи их ещё 6-8 минут на мягком огне и подавай вместе с гарниром и сметаной.',
      ],
    );

    expect(properZrazy.techniqueScore, greaterThan(flatZrazy.techniqueScore));
    expect(properZrazy.balanceScore, greaterThan(flatZrazy.balanceScore));
    expect(properZrazy.flavorScore, greaterThan(flatZrazy.flavorScore));
    expect(properZrazy.score, greaterThan(flatZrazy.score));
  });

  test('chef rules reward gravy bitochki over dry cutlet drift', () {
    final flatBitochki = assessChefRules(
      profile: DishProfile.stew,
      title: 'Биточки с подливкой',
      recipeCanonicals: const {'фарш', 'картофель', 'лук'},
      matchedCanonicals: const {'фарш', 'картофель', 'лук'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'фарш': 'Фарш',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'соль': 'Соль',
      },
      steps: const [
        'Отвари картофель на гарнир.',
        'Сформируй котлеты и обжарь их до готовности.',
        'Подавай горячими.',
      ],
    );

    final properBitochki = assessChefRules(
      profile: DishProfile.stew,
      title: 'Биточки с подливкой',
      recipeCanonicals: const {
        'фарш',
        'картофель',
        'лук',
        'морковь',
        'сметана',
      },
      matchedCanonicals: const {'фарш', 'картофель', 'лук', 'морковь'},
      supportCanonicals: const {'соль', 'перец', 'сметана'},
      displayByCanonical: const {
        'фарш': 'Фарш',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Отвари картофель на гарнир 18-20 минут, одновременно мягко прогрей лук и морковь 4-5 минут, чтобы подливка не вышла плоской.',
        'Соедини фарш с частью овощной базы, затем сформируй круглые биточки и обжарь их по 3-4 минуты с каждой стороны.',
        'Верни биточки в подливку, добавь сметану и держи их на мягком огне ещё 8-10 минут, пока подливка мягко не обволочёт мясо, затем подавай вместе с гарниром.',
      ],
    );

    expect(
      properBitochki.techniqueScore,
      greaterThan(flatBitochki.techniqueScore),
    );
    expect(
      properBitochki.balanceScore,
      greaterThan(flatBitochki.balanceScore),
    );
    expect(
      properBitochki.flavorScore,
      greaterThan(flatBitochki.flavorScore),
    );
    expect(properBitochki.score, greaterThan(flatBitochki.score));
  });

  test('chef rules reward real tefteli over flat mince rice stew', () {
    final flatTefteli = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'фарш', 'рис', 'лук'},
      matchedCanonicals: const {'фарш', 'рис', 'лук'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'фарш': 'Фарш',
        'рис': 'Рис',
        'лук': 'Лук',
        'соль': 'Соль',
      },
      steps: const [
        'Смешай фарш, рис и лук.',
        'Туши всё вместе до готовности.',
        'Подавай.',
      ],
    );

    final properTefteli = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {
        'фарш',
        'рис',
        'лук',
        'морковь',
        'томатная паста',
        'сметана',
      },
      matchedCanonicals: const {
        'фарш',
        'рис',
        'лук',
        'морковь',
        'томатная паста',
      },
      supportCanonicals: const {'соль', 'перец', 'сметана'},
      displayByCanonical: const {
        'фарш': 'Фарш',
        'рис': 'Рис',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'томатная паста': 'Томатная паста',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Соедини фарш с рисом, луком и частью моркови, затем сформируй небольшие тефтели влажными руками.',
        'Мягко прогрей лук и морковь 4-5 минут, вмешай томатную пасту и туши их под крышкой 18-22 минуты на слабом огне.',
        'В конце доведи соус через соль и перец, заверши сметаной и дай тефтелям постоять 2-3 минуты, чтобы соус мягко обволакивал их.',
      ],
    );

    expect(
      properTefteli.techniqueScore,
      greaterThan(flatTefteli.techniqueScore),
    );
    expect(properTefteli.balanceScore, greaterThan(flatTefteli.balanceScore));
    expect(properTefteli.flavorScore, greaterThan(flatTefteli.flavorScore));
    expect(properTefteli.score, greaterThan(flatTefteli.score));
  });

  test('chef rules reward real goulash over flat boiled meat stew', () {
    final flatGoulash = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'говядина', 'лук'},
      matchedCanonicals: const {'говядина', 'лук'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'лук': 'Лук',
        'соль': 'Соль',
      },
      steps: const [
        'Нарежь говядину и лук.',
        'Влей воду и туши до готовности.',
        'Подавай.',
      ],
    );

    final properGoulash = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {
        'говядина',
        'лук',
        'морковь',
        'паприка',
        'томатная паста',
        'чеснок',
      },
      matchedCanonicals: const {
        'говядина',
        'лук',
        'морковь',
        'паприка',
        'томатная паста',
      },
      supportCanonicals: const {'соль', 'перец', 'чеснок'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'паприка': 'Паприка',
        'томатная паста': 'Томатная паста',
        'чеснок': 'Чеснок',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Нарежь говядину кусочками, а лук и морковь мягко прогрей 4-5 минут, затем обжарь мясо ещё 5-6 минут до уверенного цвета.',
        'Добавь паприку, томатную пасту и немного воды, затем туши гуляш под крышкой 25-30 минут на спокойном огне, пока соус не станет гуще и глубже, а лишняя жидкость не выпарится.',
        'В конце доведи гуляш через соль, перец и чеснок, затем дай ему постоять 3-4 минуты.',
      ],
    );

    expect(
      properGoulash.techniqueScore,
      greaterThan(flatGoulash.techniqueScore),
    );
    expect(properGoulash.balanceScore, greaterThan(flatGoulash.balanceScore));
    expect(properGoulash.flavorScore, greaterThan(flatGoulash.flavorScore));
    expect(properGoulash.score, greaterThan(flatGoulash.score));
  });

  test('chef rules penalize goulash that drifts into white sauce', () {
    final whiteSauceGoulash = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {
        'говядина',
        'лук',
        'паприка',
        'сметана',
      },
      matchedCanonicals: const {'говядина', 'лук', 'паприка', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'лук': 'Лук',
        'паприка': 'Паприка',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Нарежь говядину кусочками, а лук мягко прогрей 4-5 минут, затем обжарь мясо ещё 5-6 минут.',
        'Добавь паприку и сметану, затем туши гуляш под крышкой 25-30 минут в белом соусе.',
        'Подавай горячим.',
      ],
    );

    expect(
      whiteSauceGoulash.warnings.any(
        (warning) => warning.contains('белый сметанный соус'),
      ),
      isTrue,
    );
  });

  test('chef rules reward real stroganoff over flat creamless beef stew', () {
    final flatStroganoff = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'говядина', 'лук'},
      matchedCanonicals: const {'говядина', 'лук'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'лук': 'Лук',
        'соль': 'Соль',
      },
      steps: const [
        'Нарежь говядину кусочками.',
        'Туши её с луком до мягкости.',
        'Подавай.',
      ],
    );

    final properStroganoff = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {
        'говядина',
        'лук',
        'сметана',
        'грибы',
        'горчица',
      },
      matchedCanonicals: const {'говядина', 'лук', 'сметана', 'грибы'},
      supportCanonicals: const {'соль', 'перец', 'горчица'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'лук': 'Лук',
        'сметана': 'Сметана',
        'грибы': 'Грибы',
        'горчица': 'Горчица',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Нарежь говядину тонкими полосками, а лук и грибы подготовь отдельно для мягкой соусной базы.',
        'Быстро обжарь мясо 3-4 минуты, затем прогрей лук и грибы 4-5 минут, добавь сметану и держи бефстроганов на мягком огне ещё 5-7 минут, не давая соусу бурно кипеть, чтобы сметанный соус остался гладким.',
        'В конце доведи бефстроганов через соль, перец и горчицу, затем дай соусу спокойно собраться 1-2 минуты и остаться гладким.',
      ],
    );

    expect(
      properStroganoff.techniqueScore,
      greaterThan(flatStroganoff.techniqueScore),
    );
    expect(
      properStroganoff.balanceScore,
      greaterThan(flatStroganoff.balanceScore),
    );
    expect(
      properStroganoff.flavorScore,
      greaterThan(flatStroganoff.flavorScore),
    );
    expect(properStroganoff.score, greaterThan(flatStroganoff.score));
  });

  test('chef rules penalize stroganoff that braises like goulash', () {
    final braisedStroganoff = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'говядина', 'лук', 'сметана'},
      matchedCanonicals: const {'говядина', 'лук', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'лук': 'Лук',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Нарежь говядину тонкими полосками и лук.',
        'Быстро обжарь мясо 3-4 минуты, добавь сметану и туши бефстроганов под крышкой 25-30 минут.',
        'Подавай горячим.',
      ],
    );

    expect(
      braisedStroganoff.warnings.any(
        (warning) => warning.contains('тушиться как гуляш'),
      ),
      isTrue,
    );
  });

  test('chef rules reward lentil soup with tomato depth and herbs', () {
    final flatSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'чечевица', 'вода'},
      matchedCanonicals: const {'чечевица'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'чечевица': 'Чечевица',
        'соль': 'Соль',
      },
      steps: const [
        'Промой чечевицу.',
        'Вари до мягкости.',
        'Подавай.',
      ],
    );

    final strongSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {
        'чечевица',
        'лук',
        'морковь',
        'томатная паста',
        'укроп',
      },
      matchedCanonicals: const {
        'чечевица',
        'лук',
        'морковь',
        'томатная паста',
      },
      supportCanonicals: const {'соль', 'перец', 'укроп'},
      displayByCanonical: const {
        'чечевица': 'Чечевица',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'томатная паста': 'Томатная паста',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Прогрей лук и морковь.',
        'Добавь томатную пасту и чечевицу.',
        'Вари на умеренном огне до мягкости и подавай с укропом.',
      ],
    );

    expect(strongSoup.balanceScore, greaterThan(flatSoup.balanceScore));
    expect(strongSoup.flavorScore, greaterThan(flatSoup.flavorScore));
    expect(strongSoup.score, greaterThan(flatSoup.score));
    expect(
      flatSoup.warnings.any((warning) => warning.contains('бобовому супу')),
      isTrue,
    );
  });

  test('chef rules reward red meat with aromatics and warm spice', () {
    final flatMeat = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'говядина', 'картофель'},
      matchedCanonicals: const {'говядина', 'картофель'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'картофель': 'Картофель',
        'соль': 'Соль',
      },
      steps: const [
        'Сложи всё вместе.',
        'Туши до готовности.',
        'Подавай.',
      ],
    );

    final layeredMeat = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {
        'говядина',
        'лук',
        'грибы',
        'сметана',
        'паприка',
      },
      matchedCanonicals: const {
        'говядина',
        'лук',
        'грибы',
        'сметана',
        'паприка',
      },
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'лук': 'Лук',
        'грибы': 'Грибы',
        'сметана': 'Сметана',
        'паприка': 'Паприка',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Обжарь лук и грибы.',
        'Добавь говядину, паприку и мягко туши до готовности.',
        'В конце вмешай сметану и подавай.',
      ],
    );

    expect(layeredMeat.balanceScore, greaterThan(flatMeat.balanceScore));
    expect(layeredMeat.flavorScore, greaterThan(flatMeat.flavorScore));
    expect(layeredMeat.score, greaterThan(flatMeat.score));
  });

  test('chef rules penalize heavy stew without bright finishing contrast', () {
    final heavyStew = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'говядина', 'картофель', 'сметана'},
      matchedCanonicals: const {'говядина', 'картофель', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'картофель': 'Картофель',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Обжарь говядину.',
        'Добавь картофель и сметану.',
        'Туши до мягкости и подай.',
      ],
    );

    final balancedStew = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {
        'говядина',
        'лук',
        'грибы',
        'сметана',
        'паприка',
        'лимон',
        'укроп',
      },
      matchedCanonicals: const {
        'говядина',
        'лук',
        'грибы',
        'сметана',
        'паприка',
        'лимон',
        'укроп',
      },
      supportCanonicals: const {'соль', 'перец', 'чеснок'},
      displayByCanonical: const {
        'говядина': 'Говядина',
        'лук': 'Лук',
        'грибы': 'Грибы',
        'сметана': 'Сметана',
        'паприка': 'Паприка',
        'лимон': 'Лимон',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
        'чеснок': 'Чеснок',
      },
      steps: const [
        'Обжарь говядину с луком и грибами.',
        'Добавь паприку и сметану, затем мягко туши до готовности.',
        'В конце добавь лимон и укроп, затем подай.',
      ],
    );

    expect(balancedStew.flavorScore, greaterThan(heavyStew.flavorScore));
    expect(balancedStew.score, greaterThan(heavyStew.score));
    expect(
      heavyStew.warnings.any(
        (warning) =>
            warning.contains('яркого финиша') || warning.contains('тяжёлой'),
      ),
      isTrue,
    );
  });

  test('chef rules penalize fish overloaded by spice without bright support',
      () {
    final overloadedFish = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'рыба', 'паприка', 'перец'},
      matchedCanonicals: const {'рыба', 'паприка', 'перец'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'паприка': 'Паприка',
        'перец': 'Перец',
        'соль': 'Соль',
      },
      steps: const [
        'Приправь рыбу специями.',
        'Обжарь на сковороде и подай.',
      ],
    );

    final cleanFish = assessChefRules(
      profile: DishProfile.skillet,
      recipeCanonicals: const {'рыба', 'лимон', 'укроп'},
      matchedCanonicals: const {'рыба', 'лимон', 'укроп'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'лимон': 'Лимон',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Сбрызни рыбу лимоном.',
        'Обжарь до готовности.',
        'Посыпь укропом и подай.',
      ],
    );

    expect(cleanFish.flavorScore, greaterThan(overloadedFish.flavorScore));
    expect(cleanFish.score, greaterThan(overloadedFish.score));
    expect(
      overloadedFish.warnings.any((warning) => warning.contains('рыб')),
      isTrue,
    );
  });

  test('chef rules reward sweet breakfast with creamy fresh contrast', () {
    final flatBreakfast = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'овсяные хлопья', 'сахар'},
      matchedCanonicals: const {'овсяные хлопья', 'сахар'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'овсяные хлопья': 'Овсяные хлопья',
        'сахар': 'Сахар',
        'соль': 'Соль',
      },
      steps: const [
        'Смешай хлопья с сахаром.',
        'Прогрей и подай.',
      ],
    );

    final balancedBreakfast = assessChefRules(
      profile: DishProfile.breakfast,
      recipeCanonicals: const {'овсяные хлопья', 'банан', 'йогурт'},
      matchedCanonicals: const {'овсяные хлопья', 'банан', 'йогурт'},
      supportCanonicals: const {'корица'},
      displayByCanonical: const {
        'овсяные хлопья': 'Овсяные хлопья',
        'банан': 'Банан',
        'йогурт': 'Йогурт',
        'корица': 'Корица',
      },
      steps: const [
        'Свари овсяные хлопья.',
        'Добавь банан и йогурт.',
        'Посыпь корицей и подай.',
      ],
    );

    expect(
      balancedBreakfast.flavorScore,
      greaterThan(flatBreakfast.flavorScore),
    );
    expect(balancedBreakfast.score, greaterThan(flatBreakfast.score));
    expect(
      flatBreakfast.warnings.any(
        (warning) =>
            warning.contains('приторным') ||
            warning.contains('свежего контраста'),
      ),
      isTrue,
    );
  });

  test('chef rules reward sauce that is actually reduced and bound', () {
    final looseSauce = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'курица', 'грибы', 'сметана'},
      matchedCanonicals: const {'курица', 'грибы', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'курица': 'Курица',
        'грибы': 'Грибы',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Обжарь курицу.',
        'Добавь грибы и сметану.',
        'Подавай.',
      ],
    );

    final boundSauce = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'курица', 'грибы', 'сметана'},
      matchedCanonicals: const {'курица', 'грибы', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'курица': 'Курица',
        'грибы': 'Грибы',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Обжарь курицу и грибы.',
        'Добавь сметану и мягко уварь до соуса.',
        'Вмешай соус в блюдо и подавай.',
      ],
    );

    expect(boundSauce.techniqueScore, greaterThan(looseSauce.techniqueScore));
    expect(boundSauce.score, greaterThan(looseSauce.score));
    expect(
      looseSauce.warnings.any((warning) => warning.contains('соусная часть')),
      isTrue,
    );
  });

  test('chef rules reward baked meat protected by cover and rest', () {
    final dryBake = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'свинина', 'картофель', 'паприка'},
      matchedCanonicals: const {'свинина', 'картофель', 'паприка'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'свинина': 'Свинина',
        'картофель': 'Картофель',
        'паприка': 'Паприка',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Выложи мясо и картофель в форму.',
        'Запекай до готовности и сразу подавай.',
      ],
    );

    final protectedBake = assessChefRules(
      profile: DishProfile.bake,
      recipeCanonicals: const {'свинина', 'картофель', 'паприка', 'сметана'},
      matchedCanonicals: const {'свинина', 'картофель', 'паприка', 'сметана'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'свинина': 'Свинина',
        'картофель': 'Картофель',
        'паприка': 'Паприка',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Замаринуй мясо со сметаной и паприкой.',
        'Накрой форму и запекай до готовности.',
        'Дай мясу отдохнуть пару минут и подавай.',
      ],
    );

    expect(protectedBake.techniqueScore, greaterThan(dryBake.techniqueScore));
    expect(protectedBake.score, greaterThan(dryBake.score));
    expect(
      dryBake.warnings.any((warning) =>
          warning.contains('духовке') || warning.contains('отдых')),
      isTrue,
    );
  });

  test('chef rules reward gentle fish soup over aggressive boil', () {
    final harshSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'рыба', 'картофель', 'укроп'},
      matchedCanonicals: const {'рыба', 'картофель', 'укроп'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'картофель': 'Картофель',
        'укроп': 'Укроп',
        'соль': 'Соль',
      },
      steps: const [
        'Залей водой рыбу и картофель.',
        'Кипяти до готовности.',
        'Подавай.',
      ],
    );

    final gentleSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'рыба', 'картофель', 'лук', 'укроп', 'лимон'},
      matchedCanonicals: const {'рыба', 'картофель', 'лук', 'укроп', 'лимон'},
      supportCanonicals: const {'соль', 'перец'},
      displayByCanonical: const {
        'рыба': 'Рыба',
        'картофель': 'Картофель',
        'лук': 'Лук',
        'укроп': 'Укроп',
        'лимон': 'Лимон',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Прогрей лук и добавь воду.',
        'Вари суп на слабом огне до готовности.',
        'В конце добавь лимон и укроп, затем подавай.',
      ],
    );

    expect(gentleSoup.techniqueScore, greaterThan(harshSoup.techniqueScore));
    expect(gentleSoup.score, greaterThan(harshSoup.score));
    expect(
      harshSoup.warnings.any((warning) => warning.contains('рыбный суп')),
      isTrue,
    );
  });

  test('chef rules reward green shchi over flat sorrel soup', () {
    final flatSorrelSoup = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {'щавель', 'картофель', 'яйцо', 'лук'},
      matchedCanonicals: const {'щавель', 'картофель', 'яйцо', 'лук'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'щавель': 'Щавель',
        'картофель': 'Картофель',
        'яйцо': 'Яйца',
        'лук': 'Лук',
        'соль': 'Соль',
      },
      steps: const [
        'Подготовь щавель, картофель и яйца.',
        'Влей воду и вари суп 18 минут.',
        'Подавай.',
      ],
    );

    final properGreenShchi = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {
        'щавель',
        'картофель',
        'яйцо',
        'лук',
        'морковь',
        'сметана',
        'укроп',
      },
      matchedCanonicals: const {
        'щавель',
        'картофель',
        'яйцо',
        'лук',
        'морковь',
      },
      supportCanonicals: const {'соль', 'перец', 'сметана', 'укроп'},
      displayByCanonical: const {
        'щавель': 'Щавель',
        'картофель': 'Картофель',
        'яйцо': 'Яйца',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'сметана': 'Сметана',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Подготовь щавель, картофель, яйца, лук и морковь, затем прогрей лук и морковь 4-5 минут.',
        'Влей воду и вари основу 16-18 минут, а в последние 2-3 минуты добавь щавель.',
        'Сними с огня, подай со сметаной и укропом.',
      ],
    );

    expect(
      properGreenShchi.techniqueScore,
      greaterThan(flatSorrelSoup.techniqueScore),
    );
    expect(
      properGreenShchi.balanceScore,
      greaterThan(flatSorrelSoup.balanceScore),
    );
    expect(
      properGreenShchi.flavorScore,
      greaterThan(flatSorrelSoup.flavorScore),
    );
    expect(properGreenShchi.score, greaterThan(flatSorrelSoup.score));
  });

  test('chef rules reward svekolnik over flat cold beet soup', () {
    final flatSvekolnik = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {
        'свекла',
        'кефир',
        'картофель',
        'огурец',
        'яйцо'
      },
      matchedCanonicals: const {
        'свекла',
        'кефир',
        'картофель',
        'огурец',
        'яйцо',
      },
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'свекла': 'Свекла',
        'кефир': 'Кефир',
        'картофель': 'Картофель',
        'огурец': 'Огурец',
        'яйцо': 'Яйца',
        'соль': 'Соль',
      },
      steps: const [
        'Отвари свеклу, картофель и яйца.',
        'Смешай всё с кефиром.',
        'Подавай холодным.',
      ],
    );

    final properSvekolnik = assessChefRules(
      profile: DishProfile.soup,
      recipeCanonicals: const {
        'свекла',
        'кефир',
        'картофель',
        'огурец',
        'яйцо',
        'укроп',
        'сметана',
      },
      matchedCanonicals: const {
        'свекла',
        'кефир',
        'картофель',
        'огурец',
        'яйцо',
        'укроп',
      },
      supportCanonicals: const {'соль', 'перец', 'сметана'},
      displayByCanonical: const {
        'свекла': 'Свекла',
        'кефир': 'Кефир',
        'картофель': 'Картофель',
        'огурец': 'Огурец',
        'яйцо': 'Яйца',
        'укроп': 'Укроп',
        'сметана': 'Сметана',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Отвари свеклу, картофель и яйца, затем полностью остуди свекольную основу.',
        'Нарежь свеклу, картофель, яйца, огурец и укроп.',
        'Влей кефир, доведи вкус и дай свекольнику постоять в холоде 5-7 минут, затем подавай охлаждённым.',
      ],
    );

    expect(
      properSvekolnik.techniqueScore,
      greaterThan(flatSvekolnik.techniqueScore),
    );
    expect(
      properSvekolnik.balanceScore,
      greaterThan(flatSvekolnik.balanceScore),
    );
    expect(
      properSvekolnik.flavorScore,
      greaterThan(flatSvekolnik.flavorScore),
    );
    expect(properSvekolnik.score, greaterThan(flatSvekolnik.score));
    expect(
      flatSvekolnik.warnings.any((warning) => warning.contains('свеколь')),
      isTrue,
    );
  });

  test('chef rules reward buckwheat rustic bowl over plain buckwheat', () {
    final plainBuckwheat = assessChefRules(
      profile: DishProfile.grainBowl,
      recipeCanonicals: const {'гречка'},
      matchedCanonicals: const {'гречка'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'гречка': 'Гречка',
        'соль': 'Соль',
      },
      steps: const [
        'Свари гречку.',
        'Подавай.',
      ],
    );

    final rusticBuckwheat = assessChefRules(
      profile: DishProfile.grainBowl,
      recipeCanonicals: const {
        'гречка',
        'грибы',
        'лук',
        'морковь',
        'сметана',
        'укроп',
      },
      matchedCanonicals: const {
        'гречка',
        'грибы',
        'лук',
        'морковь',
      },
      supportCanonicals: const {'соль', 'перец', 'сметана', 'укроп'},
      displayByCanonical: const {
        'гречка': 'Гречка',
        'грибы': 'Грибы',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'сметана': 'Сметана',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Промой крупу и вари гречку 15-18 минут под крышкой, сначала прогрей добавки 4-5 минут.',
        'Добавь грибы к луку и моркови, затем вмешай основу, чтобы гречка впитала вкус.',
        'Дай блюду 1-2 минуты постоять и подавай с укропом.',
      ],
    );

    expect(
      rusticBuckwheat.techniqueScore,
      greaterThan(plainBuckwheat.techniqueScore),
    );
    expect(
      rusticBuckwheat.balanceScore,
      greaterThan(plainBuckwheat.balanceScore),
    );
    expect(
      rusticBuckwheat.flavorScore,
      greaterThan(plainBuckwheat.flavorScore),
    );
    expect(rusticBuckwheat.score, greaterThan(plainBuckwheat.score));
  });

  test('chef rules reward stewed cabbage over flat cabbage boil', () {
    final flatCabbage = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {'капуста', 'лук', 'морковь'},
      matchedCanonicals: const {'капуста', 'лук', 'морковь'},
      supportCanonicals: const {'соль'},
      displayByCanonical: const {
        'капуста': 'Капуста',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'соль': 'Соль',
      },
      steps: const [
        'Сложи капусту, лук и морковь в кастрюлю.',
        'Провари и подай.',
      ],
    );

    final properStewedCabbage = assessChefRules(
      profile: DishProfile.stew,
      recipeCanonicals: const {
        'капуста',
        'лук',
        'морковь',
        'колбаса',
        'томатная паста',
        'укроп',
      },
      matchedCanonicals: const {
        'капуста',
        'лук',
        'морковь',
        'колбаса',
        'томатная паста',
      },
      supportCanonicals: const {'соль', 'перец', 'укроп'},
      displayByCanonical: const {
        'капуста': 'Капуста',
        'лук': 'Лук',
        'морковь': 'Морковь',
        'колбаса': 'Колбаса',
        'томатная паста': 'Томатная паста',
        'укроп': 'Укроп',
        'соль': 'Соль',
        'перец': 'Перец',
      },
      steps: const [
        'Подготовь капусту, лук и морковь, прогрей в самом начале лук и морковь 4-5 минут.',
        'Добавь томатную пасту и колбасу, затем туши капусту на слабом огне под крышкой 20-25 минут.',
        'Сними с огня, дай блюду пару минут постоять и подавай с укропом.',
      ],
    );

    expect(
      properStewedCabbage.techniqueScore,
      greaterThan(flatCabbage.techniqueScore),
    );
    expect(
      properStewedCabbage.balanceScore,
      greaterThan(flatCabbage.balanceScore),
    );
    expect(
      properStewedCabbage.flavorScore,
      greaterThan(flatCabbage.flavorScore),
    );
    expect(properStewedCabbage.score, greaterThan(flatCabbage.score));
    expect(
      flatCabbage.warnings
          .any((warning) => warning.contains('тушёной капусте')),
      isTrue,
    );
  });
  test('chef rules reward proper mors over boiled compote-like version', () {
    final flatMors = assessChefRules(
      profile: DishProfile.general,
      recipeCanonicals: const {'клюква', 'сахар'},
      matchedCanonicals: const {'клюква'},
      supportCanonicals: const {'сахар'},
      displayByCanonical: const {
        'клюква': 'Клюква',
        'сахар': 'Сахар',
      },
      steps: const [
        'Залей клюкву водой и кипяти 20 минут на сильном огне.',
        'Сразу разлей по стаканам.',
      ],
    );

    final properMors = assessChefRules(
      profile: DishProfile.general,
      recipeCanonicals: const {'клюква', 'сахар', 'лимон'},
      matchedCanonicals: const {'клюква', 'лимон'},
      supportCanonicals: const {'сахар'},
      displayByCanonical: const {
        'клюква': 'Клюква',
        'сахар': 'Сахар',
        'лимон': 'Лимон',
      },
      steps: const [
        'Разомни клюкву, отдели сок через сито и убери его в холод.',
        'Залей ягодный жмых водой, добавь сахар и спокойно прогрей основу 8-10 минут без бурного кипения.',
        'Процеди ягодную основу, остуди до тёплого состояния и верни отложенный сок с лимоном.',
        'Охлади морс 2-3 часа и подавай хорошо холодным.',
      ],
    );

    expect(properMors.techniqueScore, greaterThan(flatMors.techniqueScore));
    expect(properMors.balanceScore, greaterThan(flatMors.balanceScore));
    expect(properMors.flavorScore, greaterThan(flatMors.flavorScore));
    expect(properMors.score, greaterThan(flatMors.score));
    expect(
      flatMors.warnings.any((warning) => warning.contains('компот')),
      isTrue,
    );
  });

  test('chef rules reward proper kissel over flat compote-like version', () {
    final flatKissel = assessChefRules(
      profile: DishProfile.general,
      recipeCanonicals: const {'клюква', 'сахар', 'крахмал'},
      matchedCanonicals: const {'клюква'},
      supportCanonicals: const {'сахар'},
      displayByCanonical: const {
        'клюква': 'Клюква',
        'сахар': 'Сахар',
        'крахмал': 'Крахмал',
      },
      steps: const [
        'Залей клюкву водой, добавь сахар и крахмал, затем кипяти 10 минут на сильном огне.',
        'Сразу разлей по стаканам.',
      ],
    );

    final properKissel = assessChefRules(
      profile: DishProfile.general,
      recipeCanonicals: const {'клюква', 'сахар', 'крахмал', 'лимон'},
      matchedCanonicals: const {'клюква', 'лимон'},
      supportCanonicals: const {'сахар'},
      displayByCanonical: const {
        'клюква': 'Клюква',
        'сахар': 'Сахар',
        'крахмал': 'Крахмал',
        'лимон': 'Лимон',
      },
      steps: const [
        'Разомни клюкву, залей ягодную основу водой и спокойно прогрей 8-10 минут.',
        'Процеди основу через сито, а отдельно разведи крахмал в холодной воде без комков.',
        'Верни основу на спокойный огонь, добавь сахар, затем тонкой струйкой влей разведённый крахмал, постоянно помешивая, и доведи до мягкой густоты.',
        'Сними с огня, добавь немного лимона и подавай тёплым как густой напиток или охлаждённым как ягодный десерт.',
      ],
    );

    expect(
      properKissel.techniqueScore,
      greaterThan(flatKissel.techniqueScore),
    );
    expect(properKissel.balanceScore, greaterThan(flatKissel.balanceScore));
    expect(properKissel.flavorScore, greaterThan(flatKissel.flavorScore));
    expect(properKissel.score, greaterThan(flatKissel.score));
    expect(
      flatKissel.warnings.any((warning) => warning.contains('кисель')),
      isTrue,
    );
  });

  test('chef rules reward proper berry jam over rushed syrup version', () {
    final flatJam = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'клюква', 'сахар'},
      matchedCanonicals: const {'клюква'},
      supportCanonicals: const {'сахар'},
      displayByCanonical: const {
        'клюква': 'Клюква',
        'сахар': 'Сахар',
      },
      steps: const [
        'Засыпь клюкву сахаром и сразу поставь на сильный огонь.',
        'Прокипяти несколько минут и сразу подавай к чаю.',
      ],
    );

    final properJam = assessChefRules(
      profile: DishProfile.salad,
      recipeCanonicals: const {'клюква', 'сахар', 'лимон'},
      matchedCanonicals: const {'клюква', 'лимон'},
      supportCanonicals: const {'сахар'},
      displayByCanonical: const {
        'клюква': 'Клюква',
        'сахар': 'Сахар',
        'лимон': 'Лимон',
      },
      steps: const [
        'Перебери клюкву, засыпь ягоды сахаром и оставь на 30-40 минут, чтобы они дали сок.',
        'Поставь ягоды на слабый огонь, дождись пока сахар полностью растворится, и снимай пену по мере появления.',
        'Вари до густого сиропа, чтобы капля держалась на холодной тарелке, а в конце добавь немного лимона.',
        'Разлей варенье по чистым сухим банкам, полностью остуди и убери в холод.',
      ],
    );

    expect(properJam.techniqueScore, greaterThan(flatJam.techniqueScore));
    expect(properJam.balanceScore, greaterThan(flatJam.balanceScore));
    expect(properJam.flavorScore, greaterThan(flatJam.flavorScore));
    expect(properJam.score, greaterThan(flatJam.score));
    expect(
      flatJam.warnings.any((warning) => warning.contains('варень')),
      isTrue,
    );
  });
}
